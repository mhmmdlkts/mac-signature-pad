module.exports.getActionNeedMailOptions = function (from, to, name, url) {

    return {
        from: from,
        to: to,
        subject: 'Aktion erforderlich: Mac Versicherung',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto;">
                <h2 style="color: #333;">Aktion erforderlich</h2>
                <p style="color: #555; font-size: 16px;">Hallo ${name},</p>
                <p style="color: #555; font-size: 16px;">vielen Dank für Ihre Registrierung bei MAC. Um fortzufahren, klicken Sie bitte auf den folgenden Button:</p>
                <a href="${url}" style="display: inline-block; padding: 10px 20px; color: white; background-color: #007BFF; text-decoration: none; border-radius: 4px; margin-top: 20px; font-weight: bold;">Fortfahren</a>
                <p style="color: #555; font-size: 16px;">Liebe Grüße,</p>
                <p style="color: #555; font-size: 16px;">Ihr MAC-Team</p>
            </div>
    `
    }
};

module.exports.getAfterSignedMailOption = function (from, to, name, vollmachtPdf, protokollPdf) {

    return {
        from: from,
        to: to,
        subject: 'MAC Dokumente',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto;">
                <p style="color: #555; font-size: 16px;">Hallo ${name},</p>
                <p style="color: #555; font-size: 16px;">wir haben Ihre Unterlagen erhalten und Danken für Ihr entgegengebrachtes Vertrauen.  Die MAC Agentur OG und Ihre Partner stehen Ihnen in Versicherungsangelegenheiten zur Seite.</p>
                <p style="color: #555; font-size: 16px;">Sämtliche Änderungen, Schadensmeldungen und Fragen usw. können Sie unter der E-Mail-Adresse office@mac-versicherung.at an uns richten.</p>
                <p style="color: #555; font-size: 16px;">Mit freundlichen Grüßen</p>
                <p style="color: #555; font-size: 16px;">Ihr MAC-Team</p>
            </div>
        `,
        attachments: [
            {
                filename: 'beratungsprotokoll.pdf',
                content: protokollPdf,
                encoding: 'base64',
            },
            {
                filename: 'vollmacht.pdf',
                content: vollmachtPdf,
                encoding: 'base64',
            },
        ],
    }
};