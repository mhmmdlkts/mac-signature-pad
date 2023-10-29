const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const config = require('./config');
const mailTemplates = require('./mail_templates');
const axios = require('axios');
const cors = require('cors')({origin: 'https://macpad.kreiseck.com'});


admin.initializeApp();


const howManyDaysValidBprotokoll = 365 * 3;
const howManyDaysValidVollmacht = 365 * 3;
const howManyDaysBeforeExpWarn = 45;

let transporter = nodemailer.createTransport({
    host: 'smtp.easyname.com',
    port: 465, // Oder 465, je nach Ihrem SMTP-Server
    secure: true, // true für 465, false für andere Ports
    auth: {
        user: config.email,
        pass: config.password
    }
});


exports.onCustomerCreate = functions.region('europe-west1').firestore
    .document('customers/{customerId}')
    .onCreate(async (snap, context) => {

        await sendMail(snap.id)
    });

async function sendSms(customerId) {
    const customer = (await admin.firestore().collection('customers').doc(customerId).get()).data();
    const name = customer.name + customer.surname;
    const phone = customer.phone;
    const auth = Buffer.from(`${config.TWILIO_ACCOUNT_SID}:${config.TWILIO_AUTH_TOKEN}`).toString('base64');

    try {
        const response = await axios.post(url, new URLSearchParams({
            From: config.TWILIO_PHONE_NUMBER,
            To: phone,
            Body: 'Hallo ' + name + ',\n\nvielen Dank für Ihre Registrierung bei MAC. Bitte unterschreiben Sie die Dokumente unter folgendem Link: ' + getSignUrl(customer.token) + '\n\nViele Grüße,\nIhr MAC-Team'
        }).toString(), {
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/x-www-form-urlencoded',
            },
        });

        if (response.status === 201) {
            await admin.firestore().collection('customers').doc(customerId).update({
                smsSentTime: new Date()
            });
            console.log('Message sent');
        } else {
            console.log('Failed to send message');
        }
    } catch (error) {
        console.log('Failed to send message: ', error);
    }

}

function getSignUrl(token) {
    return `https://macpad.kreiseck.com/?token=${token}#/sign`;
}

async function sendMail(customerId) {
    const customer = (await admin.firestore().collection('customers').doc(customerId).get()).data();

    const mailOptions = mailTemplates.getActionNeedMailOptions(config.email, customer.email, getSignUrl(customer.token));

    let check = false;

    await transporter.sendMail(mailOptions)
        .then(() => {
            check = true;
            return console.log('Neue Willkommens-E-Mail gesendet an:', customer.email);
        }).catch((error) => {
        return console.error('Es gab einen Fehler beim Senden der E-Mail:', error);
    });

    if (check) {
        await admin.firestore().collection('customers').doc(customerId).update({
            emailSentTime: new Date()
        });
    }

    return
}

exports.signPds = functions.region('europe-west1').https.onRequest(async (request, response) => {

    return cors(request, response, async () => {
        if (request.method !== 'POST') {
            response.status(400).send('Invalid Request');
            return;
        }
        const requiredFields = ['token', 'userId', 'signature', 'vollmachtVersion', 'bprotokollVersion', 'bprotokollPdfUrl', 'vollmachtPdfUrl', 'advisorName', 'advisorId'];

        for (const field of requiredFields) {
            if (!request.body[field]) {
                console.log(`Missing ${field} field`)
                response.status(400).send(`Missing ${field} field`);
                return;
            }
        }

        const customerDoc = admin.firestore().collection('customers').doc(request.body.userId)
        const customer = (await customerDoc.get()).data();
        if (customer==undefined || customer.token !== request.body.token) {
            response.status(400).send('Invalid token');
            return;
        }

        const bprotokollExp = new Date(Date.now() + howManyDaysValidBprotokoll * 24 * 60 * 60 * 1000);
        const vollmachtExp = new Date(Date.now() + howManyDaysValidVollmacht * 24 * 60 * 60 * 1000);
        const docRef = await customerDoc.collection('signatures').add({
            signature: request.body.signature,
            vollmachtVersion: request.body.vollmachtVersion,
            bprotokollVersion: request.body.bprotokollVersion,
            bprotokollExp: bprotokollExp,
            vollmachtExp: vollmachtExp,
            vollmachtPdfUrl: request.body.vollmachtPdfUrl,
            bprotokollPdfUrl: request.body.bprotokollPdfUrl,
            signedAt: new Date(),
            advisorName: request.body.advisorName,
            advisorId: request.body.advisorId
        });

        await customerDoc.update({
            lastSignatureId: docRef.id,
            token: null
        })

        if (customer.email != undefined || customer.email != null) {
            await sendMailWithAttachments(request.body.vollmachtPdfUrl, request.body.vollmachtPdfUrl, customer.email);
        }

        response.send("Hello from Firebase!");
    });
});


exports.weekdayJob = functions.pubsub.schedule('0 10 1 * *').timeZone('Europe/Berlin').onRun((context) => {

    const customers = admin.firestore().collection('customers');
    const now = new Date();
    const bprotokollExp = new Date(now.getTime() + howManyDaysBeforeExpWarn * 24 * 60 * 60 * 1000);

    customers.where('bprotokollExp', '<', bprotokollExp).get().then((snapshot) => {
        snapshot.forEach((doc) => {
            const customer = doc.data();
            if (customer.email != undefined || customer.email != null) {
                sendMail(doc.id);
            }
        });
    });
    return null;
});

async function sendMailWithAttachments(vollmachtPdf, protokollPdf, customerEmail) {

    const vollmachtResponse = await axios({
        method: 'get',
        url: vollmachtPdf,
        responseType: 'arraybuffer',
    });

    const protokollResponse = await axios({
        method: 'get',
        url: protokollPdf,
        responseType: 'arraybuffer',
    });

    const mailOptions = mailTemplates.getAfterSignedMailOption(config.email, customerEmail, vollmachtResponse.data, protokollResponse.data);

    // E-Mail senden
    await transporter.sendMail(mailOptions)
        .then(() => {
            console.log('Neue Willkommens-E-Mail gesendet an:', customerEmail);
        })
        .catch((error) => {
            console.error('Es gab einen Fehler beim Senden der E-Mail:', error);
        });
}


exports.getUserData = functions.region('europe-west1').https.onRequest(async (request, response) => {
    return cors(request, response, async () => {
        const token = request.query.token;
        const timestamp = parseInt(token.substring(0, 16));
        if (timestamp < Date.now()) {
            response.status(400).send('Invalid token');
            return;
        }

        const customer = (await admin.firestore().collection('customers').where('token', '==', token).get()).docs[0];
        if (!customer) {
            response.status(404).send('Customer not found');
            return;
        }

        const customerData = customer.data();
        customerData.id = customer.id;

        response.status(200).json(customerData);
    });
});


exports.sendCustomerNotification = functions.region('europe-west1').https.onRequest(async (request, response) => {
    return cors(request, response, async () => {
        if (request.method !== 'POST') {
            response.status(400).send('Invalid Request');
            return;
        }
        const requiredFields = ['customerId', 'token', 'email', 'sms'];

        for (const field of requiredFields) {
            if (request.body[field] == undefined || request.body[field] == null) {
                console.log(`Missing ${field} field`)
                response.status(400).send(`Missing ${field} field`);
                return;
            }
        }

        // check is email and sms boolean
        if (typeof request.body.email !== 'boolean' || typeof request.body.sms !== 'boolean') {
            response.status(400).send('Invalid Request');
            return;
        }

        if (!request.body.email && !request.body.sms) {
            response.status(400).send('Invalid Request');
            return;
        }

        // const customer = (await admin.firestore().collection('customers').doc(request.body.customerId).get()).data();
        await admin.firestore().collection('customers').doc(request.body.customerId).update({
            token: request.body.token
        });

        if (request.body.email) {
            await sendMail(request.body.customerId)
        }
        if (request.body.sms) {
            await sendSms(request.body.customerId)
        }
    });
})
