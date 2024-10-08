import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";
import dotenv from 'dotenv';

// Cargar variables de entorno desde el archivo .env
dotenv.config();

admin.initializeApp();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || functions.config().stripe.secret, {
    apiVersion: "2024-06-20", // Asegúrate de que esta sea la última versión de la API
});

// Función para crear una sesión de checkout en Stripe
export const createCheckoutSession = functions.https.onCall(async (data, context) => {
    const { userId, priceId } = data;

    // Validar userId y priceId antes de proceder
    console.log("Received userId:", userId);
    console.log("Received priceId:", priceId);
    if (!userId || !priceId) {
        console.error("Missing userId or priceId");
        throw new functions.https.HttpsError('invalid-argument', 'User ID and Price ID are required');
    }

    try {
        // Obtener el ID de cliente de Stripe desde la colección customers en Firestore
        const customerDoc = await admin.firestore().collection('customers').doc(userId).get();
        const stripeCustomerId = customerDoc.data()?.stripeId;
        console.log("Fetched stripeCustomerId:", stripeCustomerId);

        if (!stripeCustomerId) {
            console.error("Stripe customer ID not found for user:", userId);
            throw new functions.https.HttpsError('not-found', 'Stripe customer not found');
        }

        // Crear la sesión de checkout en Stripe
        console.log("Attempting to create Stripe checkout session for customer:", stripeCustomerId);

        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            mode: 'subscription',
            customer: stripeCustomerId,
            line_items: [
                {
                    price: priceId,
                    quantity: 1,
                },
            ],
            metadata: {
                userId: userId,  // Aquí se asegura que el userId esté presente en metadata
            },
            success_url: 'http://localhost:65214/#/success',
            cancel_url: 'http://localhost:65214/#/cancel',
        });
        console.log("Stripe checkout session created successfully:", session.id);
        return { sessionId: session.id };

    } catch (error: unknown) {
        if (error instanceof Stripe.errors.StripeError) {
            console.error("Stripe error:", error);
            console.error("Error type:", error.type);
            console.error("Error message:", error.message);
            throw new functions.https.HttpsError('internal', 'Unable to create checkout session', error.message);
        } else if (error instanceof Error) {
            console.error("Unknown error occurred:", error.message);
            throw new functions.https.HttpsError('internal', 'An unknown error occurred', error.message);
        } else {
            console.error("Unknown error type:", error);
            throw new functions.https.HttpsError('internal', 'An unknown error occurred');
        }
    }
});

// Función para manejar la creación de un nuevo cliente en Stripe
export const createStripeCustomer = functions.auth.user().onCreate(
    async (user) => {
        try {
            const customer = await stripe.customers.create({
                email: user.email || "",
            });
            console.log("Stripe customer created:", customer.id);

            await admin.firestore().collection("customers").doc(user.uid).set(
                {
                    stripeId: customer.id,
                    subscriptionType: "free", // Inicialmente, el usuario es "free"
                    maxIncidents: 50, // Máximo número de incidentes para usuarios "free"
                },
                {merge: true}
            );
            console.log("Customer document updated in Firestore for user:", user.uid);
        } catch (error: unknown) {
            if (error instanceof Stripe.errors.StripeError) {
                console.error("Stripe error:", error);
                console.error("Error type:", error.type);
                console.error("Error message:", error.message);
                throw new functions.https.HttpsError('internal', 'Unable to create Stripe customer', error.message);
            } else if (error instanceof Error) {
                console.error("Unknown error occurred:", error.message);
                throw new functions.https.HttpsError('internal', 'An unknown error occurred', error.message);
            } else {
                console.error("Unknown error type:", error);
                throw new functions.https.HttpsError('internal', 'An unknown error occurred');
            }
        }
    }
);

// Función para manejar los pagos en Stripe
export const handleStripePayment = functions.https.onCall(
    async (data, context) => {
        const userId = context.auth?.uid;

        if (!userId) {
            console.error("User is not authenticated");
            throw new functions.https.HttpsError(
                "failed-precondition",
                "The function must be called while authenticated."
            );
        }

        try {
            const customerDoc = await admin.firestore()
                .collection("customers")
                .doc(userId)
                .get();

            if (!customerDoc.exists) {
                console.error("User document not found in Firestore for user:", userId);
                throw new functions.https.HttpsError("not-found", "User not found");
            }

            const amount = data.amount; // El monto en centavos
            console.log("Creating payment intent for amount:", amount);

            const paymentIntent = await stripe.paymentIntents.create({
                amount,
                currency: "mxn",
                customer: customerDoc.data()?.stripeId || "",
            });

            console.log("Payment intent created successfully:", paymentIntent.id);
            return {
                clientSecret: paymentIntent.client_secret,
            };
        } catch (error: unknown) {
            if (error instanceof Stripe.errors.StripeError) {
                console.error("Stripe error:", error);
                console.error("Error type:", error.type);
                console.error("Error message:", error.message);
                throw new functions.https.HttpsError('internal', 'Unable to create payment intent', error.message);
            } else if (error instanceof Error) {
                console.error("Unknown error occurred:", error.message);
                throw new functions.https.HttpsError('internal', 'An unknown error occurred', error.message);
            } else {
                console.error("Unknown error type:", error);
                throw new functions.https.HttpsError('internal', 'An unknown error occurred');
            }
        }
    }
);

// Función para actualizar el tipo de suscripción
export const updateSubscription = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change) => {
        const newData = change.after.data();
        console.log("Updating subscription for user:", change.after.id);

        const maxIncidents =
            newData.subscriptionType === "premium" ? 200 : 50;

        try {
            await change.after.ref.update({
                maxIncidents,
            });
            console.log("Subscription updated successfully for user:", change.after.id);
        } catch (error: unknown) {
            if (error instanceof Error) {
                console.error("Error updating subscription for user:", change.after.id, error.message);
            } else {
                console.error("Unknown error type while updating subscription:", error);
            }
        }
    });
