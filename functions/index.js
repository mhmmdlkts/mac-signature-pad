const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const config = require('./config');
const mailTemplates = require('./mail_templates');
const axios = require('axios');
const cors = require('cors')({origin: 'https://signature.mac-versicherung.at'});
const fs = require('fs');
const os = require('os');
const path = require('path');



admin.initializeApp();


const howManyDaysValidBprotokoll = 365 * 3;
const howManyDaysValidVollmacht = 365 * 3;
const howManyDaysBeforeExpWarn = 45;

let transporter = nodemailer.createTransport({
    service: "Outlook365",
    auth: {
        user: config.email,
        pass: config.password
    }
});

exports.getPdf = functions.runWith({
    timeoutSeconds: 540,
    memory: '2GB'
}).region('europe-west1').https.onRequest(async (request, response) => {

    return cors(request, response, async () => {
        if (request.method !== 'POST') {
            response.status(400).send('Invalid Request');
            return;
        }
        const requiredFields = ['token', 'pdf_name', 'customer_id'];

        for (const field of requiredFields) {
            if (!request.body[field]) {
                console.log(`Missing ${field} field`)
                response.status(400).send(`Missing ${field} field`);
                return;
            }
        }

        const customerDoc = admin.firestore().collection('customers').doc(request.body.customer_id)
        const customer = (await customerDoc.get()).data();
        if (customer==undefined || customer.token !== request.body.token) {
            response.status(400).send('Invalid token');
            return;
        }

        const now = getCurrentDateFormatted()
        const pdf_name = request.body.pdf_name;
        const signature = request.body.signature != null ? request.body.signature : '';
        const readableNextTermin = customer.nextTermin!=null?getReadableDate(customer.nextTermin):'';
        const placeholders = {
            name: customer.name + " " + customer.surname,
            phone_email: customer.phone + " / " + customer.email,
            uid_stnr: customer.uid + " / " + customer.stnr,
            birthdate: getReadableDate(customer.birthdate),
            next_termin: readableNextTermin,
            advisor_name: customer.advisorName,
            signature_name: customer.name + " " + customer.surname,
            city_date_customer: customer.city + ", " + now,
            city_date_advisor: "Villach, " + now,
            address: customer.zip + " " + customer.city + ", " + customer.street,
            date: now,
            signature: signature
        }

        const details = customer.details??[];
        for (let i = 0; i < details.length; i++) {
            const element = details[i];
            placeholders[element.code+'-yes'] = element.status == 0?'x':'';
            placeholders[element.code+'-no'] = element.status == 1?'x':'';
            placeholders[element.code+'-change'] = element.status == 2?'x':'';
            placeholders[element.code+'-note'] = element.notes??'';
        }

        try {
            const url = 'https://europe-west1-mac-signature.cloudfunctions.net/createPdf';
            const res = await axios.post(url, {
                pdf_name: pdf_name,
                placeholders: placeholders
            });

            if (res.status === 200) {
                response.setHeader('Content-Type', 'application/json');
                return response.status(200).send({
                    base64Pdf: res.data,
                });
            } else {
                console.log('Failed to send message');
                return response.status(400).send('Failed to send message a');
            }
        } catch (error) {
            console.log('Failed to send message: ', error);
            return response.status(400).send('Failed to send message b ' + error);
        }
        return response.status(400).send('Failed to send message c');
    });
});

function getCurrentDateFormatted() {
    const today = new Date();
    const day = today.getDate().toString().padStart(2, '0');
    const month = (today.getMonth() + 1).toString().padStart(2, '0'); // Monate sind von 0-11
    const year = today.getFullYear();

    return `${day}.${month}.${year}`;
}

function getReadableDate(timestamp) {
    // Konvertieren des Firestore Timestamps in ein JavaScript-Date-Objekt in UTC
    const date = new Date((timestamp._seconds + 7200) * 1000);

    // Manuelle Umwandlung in UTC
    const utcDate = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());

    const day = utcDate.getUTCDate().toString().padStart(2, '0');
    const month = (utcDate.getUTCMonth() + 1).toString().padStart(2, '0');
    const year = utcDate.getUTCFullYear();

    return `${day}.${month}.${year}`;
}


exports.onCustomerCreate = functions.region('europe-west1').firestore
    .document('customers/{customerId}')
    .onCreate(async (snap, context) => {

        await sendMail(snap.id)
    });

async function sendSms(customerId) {
    const customer = (await admin.firestore().collection('customers').doc(customerId).get()).data();
    const name = customer.name + " " + customer.surname;
    const phone = customer.phone;

    const url = 'https://api.smsapi.com/sms.do';
    const senderName = 'MAC Agentur';
    const messageContent = `Hallo ${name},\n\nvielen Dank für Ihre Registrierung bei MAC. Bitte unterschreiben Sie die Dokumente unter folgendem Link: ${getSignUrl(customer.token)}\n\nLiebe Grüße,\nIhr MAC-Team`;

    try {
        const response = await axios.get(url, {
            params: {
                from: senderName,
                to: phone,
                message: messageContent,
                format: 'json'
            },
            headers: {
                'Authorization': `Bearer ${config.SMS_API_KEY}`
            }
        });

        if (response.status === 200) {
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
    return `https://signature.mac-versicherung.at/?token=${token}#/sign`;
}

async function sendMail(customerId, autoRenew = false) {
    const customer = (await admin.firestore().collection('customers').doc(customerId).get()).data();

    let mailOptions
    if (autoRenew) {
        mailOptions = mailTemplates.getAutoRenewMailOptions(config.email, customer.email, customer.name + " " + customer.surname, getSignUrl(customer.token));
    } else {
        mailOptions = mailTemplates.getActionNeedMailOptions(config.email, customer.email, customer.name + " " + customer.surname, getSignUrl(customer.token));
    }

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

exports.signPdfs = functions.region('europe-west1').https.onRequest(async (request, response) => {

    return cors(request, response, async () => {
        if (request.method !== 'POST') {
            response.status(400).send('Invalid Request');
            return;
        }
        const requiredFields = ['token', 'userId', 'signature'];

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

        const versionProtokoll = 'v1';
        const versionVollmacht = 'v1';

        response.status(200).send('Success');

        const vollmachtBase64 = await axios({
            method: 'post',  url: 'https://europe-west1-mac-signature.cloudfunctions.net/getPdf',
            headers: {'Content-Type': 'application/json'},
            data : {
                pdf_name: 'vollmacht_' + versionVollmacht,
                token: request.body.token,
                customer_id: request.body.userId,
                signature: request.body.signature
            }
        });

        const protokollBase64 = await axios({
            method: 'post',  url: 'https://europe-west1-mac-signature.cloudfunctions.net/getPdf',
            headers: {'Content-Type': 'application/json'},
            data : JSON.stringify({
                pdf_name: 'protokoll_' + versionProtokoll,
                token: request.body.token,
                customer_id: request.body.userId,
                signature: request.body.signature
            })
        });

        const tempFilePathVollmacht = path.join(os.tmpdir(), `vollmacht_${versionVollmacht}.pdf`);
        await fs.promises.writeFile(tempFilePathVollmacht, Buffer.from(vollmachtBase64.data.base64Pdf, 'base64'));

        // upload to firebase storage as pdf and get url
        const vollmachtStorage = await admin.storage().bucket().upload(tempFilePathVollmacht, {
            destination: `${request.body.userId}/pdfs/vollmacht_${versionVollmacht}.pdf` });
        await vollmachtStorage[0].makePublic();
        const vollmachtPdfUrl = vollmachtStorage[0].metadata.mediaLink;

        const tempFilePathProtokoll = path.join(os.tmpdir(), `protokoll_${versionProtokoll}.pdf`);
        await fs.promises.writeFile(tempFilePathProtokoll, Buffer.from(protokollBase64.data.base64Pdf, 'base64'));

        const bprotokollStorage = await admin.storage().bucket().upload(tempFilePathProtokoll, {
            destination: `${request.body.userId}/pdfs/protokoll_${versionProtokoll}.pdf` });
        await bprotokollStorage[0].makePublic();
        const bprotokollPdfUrl = bprotokollStorage[0].metadata.mediaLink;

        const docRef = await customerDoc.collection('signatures').add({
            signature: request.body.signature,
            bprotokollExp: bprotokollExp,
            vollmachtExp: vollmachtExp,
            vollmachtPdfUrl: vollmachtPdfUrl,
            bprotokollPdfUrl: bprotokollPdfUrl,
            signedAt: new Date(),
            advisorName: customer.advisorName,
            advisorId: customer.advisorId,
            vollmachtVersion: versionVollmacht,
            bprotokollVersion: versionProtokoll,
        });

        await customerDoc.update({
            lastSignatureId: docRef.id,
            bprotokollExp: bprotokollExp,
            vollmachtExp: vollmachtExp,
            token: null
        })

        if (customer.email != undefined || customer.email != null) {
            await sendMailWithAttachments(vollmachtPdfUrl, bprotokollPdfUrl, customer.email, customer.name + " " + customer.surname);
        }
    });
});


exports.weekdayJob = functions.pubsub.schedule('0 9 9 * *').timeZone('Europe/Berlin').onRun((context) => {
    checkAndSendMail()
});

async function checkAndSendMail() {
    const now = new Date();
    const bprotokollExp = new Date(now.getTime() + howManyDaysBeforeExpWarn * 24 * 60 * 60 * 1000);
    console.log('bprotokollExp', bprotokollExp);

    admin.firestore().collection('customers').where('bprotokollExp', '<', bprotokollExp).get().then((snapshot) => {
        console.log('bprotokollExp', snapshot.size);

        snapshot.forEach((doc) => {
            console.log(doc.id)
            const customer = doc.data();
            console.log(customer.email)
            if (customer.email != undefined || customer.email != null) {
                sendMail(doc.id, true);
            }
        });
    });
    return null;
}

async function sendMailWithAttachments(vollmachtPdf, protokollPdf, customerEmail, name) {

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

    const mailOptions = mailTemplates.getAfterSignedMailOption(config.email, customerEmail, name, vollmachtResponse.data, protokollResponse.data);

    // E-Mail senden
    await transporter.sendMail(mailOptions)
        .then(() => {
            console.log('Neue Willkommens-E-Mail gesendet an:', customerEmail);
        })
        .catch((error) => {
            console.error('Es gab einen Fehler beim Senden der E-Mail:', error);
        });
}

exports.getAllUsers = functions.region('europe-west1').runWith({timeoutSeconds: 540, memory: '8GB'}).https.onRequest(async (request, response) => {
    const authorization = request.headers.authorization;
    const apiKey = authorization.split('Bearer ')[1];

    if (apiKey != config.FUNCTIONS_KEY) {
        return response.status(400).send('Ungültiger Request: Authorization key ist falsch.');
    }
    const customers = await admin.firestore().collection('customers').get();
    let csvData = 'Nachname;Name;Geburtsdatum;PLZ;Ort;Strasse;Begin;Ablauf;AdivsorName;Telefon;E-Mail;Vollmacht;Beratungsprotokoll\n';

    const formatBirthdate = (birthdate) => {
        if (!birthdate) return '';

        let date;
        if (typeof birthdate.toDate === 'function') {
            date = birthdate.toDate();
        } else if (birthdate instanceof Date) {
            date = birthdate;
        } else {
            date = new Date(birthdate);
        }

        date.setHours(date.getHours() + 12);

        if (isNaN(date)) return 'Ungültiges Datum';

        return date.toLocaleDateString('de-AT');
    };

    const formatTimestamp = (timestamp) => {
        if (!timestamp) return '';

        const date = timestamp.toDate ? timestamp.toDate() : timestamp;
        return date instanceof Date ? date.toLocaleDateString('de-AT') : '';
    };

    const customerData = (customer, signature) => {
        return {
            surname: customer.surname || '',
            name: customer.name || '',
            birthdate: formatBirthdate(customer.birthdate),
            zip: customer.zip || '',
            city: customer.city || '',
            street: customer.street || '',
            begin: formatTimestamp(signature.data().signedAt),
            ablauf: formatTimestamp(signature.data().bprotokollExp),
            advisorName: customer.advisorName || '',
            phone: customer.phone || '',
            email: customer.email || '',
            vollmacht: signature.data().vollmachtPdfUrl || '',
            beratungsprotokoll: signature.data().bprotokollPdfUrl || '',
        };
    };

    for (let i = 0; i < customers.size; i++) {
        const customer = customers.docs[i].data();
        try {
            const signature = await admin.firestore().collection('customers').doc(customers.docs[i].id).collection('signatures').doc(customer.lastSignatureId).get();

            const cData = customerData(customer, signature);

            csvData += `${cData.surname};${cData.name};${cData.birthdate};${cData.zip};${cData.city};${cData.street};${cData.begin};${cData.ablauf};${cData.advisorName};${cData.phone};${cData.email};${cData.vollmacht};${cData.beratungsprotokoll}\n`
        } catch (e) {
            console.log(e)
        }
    }
    return response
        .set({
            "Content-Type": "text/csv",
            "Content-Disposition": `attachment; filename="users.csv"`,
        })
        .send(csvData)
});

exports.aaabbbccc = functions.region('europe-west1').https.onRequest(async (request, response) => {

    const customers = await admin.firestore().collection('customers').get();

    for (let i = 0; i < customers.size; i++) {
        const customer = customers.docs[i].data();
        try {
            let bprotokollExp = null;
            let vollmachtExp = null;
            let street = customer.street;
            let country = customer.country ?? '';

            if (street == undefined || street == null || street == '') {
                street = country;
            }

            try {
                const signature = await admin.firestore().collection('customers').doc(customers.docs[i].id).collection('signatures').doc(customer.lastSignatureId).get();
                bprotokollExp = signature.data().bprotokollExp;
                vollmachtExp = signature.data().vollmachtExp;
            } catch (e) {
            }

            await admin.firestore().collection('customers').doc(customers.docs[i].id).update({
                'bprotokollExp': bprotokollExp,
                'vollmachtExp': vollmachtExp,
                'street': street,
                'country': admin.firestore.FieldValue.delete()
            });
        } catch (e) {
            console.log(e)
        }
    }
    return response.send(csvData)
});

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


exports.removeAdvisor = functions.region('europe-west1').https.onRequest(async (request, response) => {
    return cors(request, response, async () => {
        if (request.method !== 'POST') {
            response.status(400).send('Invalid Request');
            return;
        }
        const requiredFields = ['myId', 'idToDelete'];

        for (const field of requiredFields) {
            if (request.body[field] == undefined || request.body[field] == null) {
                console.log(`Missing ${field} field`)
                response.status(400).send(`Missing ${field} field`);
                return;
            }
        }

        const myId = request.body.myId;
        const idToDelete = request.body.idToDelete;
        const a = (await admin.firestore().collection('advisors').doc(myId).get()).data();
        if (a == undefined || a == null || !a.role || a.role !== 'admin') {
            response.status(400).send('Invalid Request');
            return;
        }
        await admin.firestore().collection('advisors').doc(idToDelete).delete();
        await admin.auth().deleteUser(idToDelete);
        response.status(200).send('Success');
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
        response.status(200).send('Success');
    });
})
