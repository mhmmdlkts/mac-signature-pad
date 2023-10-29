const config = require("./config");
module.exports.getActionNeedMailOptions = function (from, to, url) {
    return {
        from: from,
        to: to,
        subject: 'Aktion erforderlich: Bitte fortsetzen',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto;">
                <h2 style="color: #333;">Aktion erforderlich</h2>
                <p style="color: #555; font-size: 16px;">Um fortzufahren, klicken Sie bitte auf den folgenden Button:</p>
                <a href="${url}" style="display: inline-block; padding: 10px 20px; color: white; background-color: #007BFF; text-decoration: none; border-radius: 4px; margin-top: 20px; font-weight: bold;">Fortfahren</a>
                <p style="color: #777; font-size: 14px; margin-top: 30px;">Falls Sie Fragen haben, kontaktieren Sie uns bitte.</p>
            </div>
    `
    }
};

module.exports.getAfterSignedMailOption = function (from, to, vollmachtPdf, protokollPdf) {
    return {
        from: from,
        to: to,
        subject: 'MAC Dokumente',
        text: 'Anbei die Dokumente',
        attachments: [
            {
                filename: 'beratungsprotokoll.pdf',
                content: vollmachtPdf,
                encoding: 'base64',
            },
            {
                filename: 'vollmacht.pdf',
                content: protokollPdf,
                encoding: 'base64',
            },
        ],
    }
};