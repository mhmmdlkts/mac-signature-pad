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

module.exports.getAutoRenewMailOptions = function (from, to, name, url) {

    return {
        from: from,
        to: to,
        subject: 'Aktion erforderlich: Mac Versicherung',
        html: `<div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto;">
    <h2 style="color: #333;">Überprüfung Ihrer Versicherungsdokumente</h2>
    <p style="color: #555; font-size: 16px;">Hallo ${name},</p>
    <p style="color: #555; font-size: 16px;">im Rahmen unserer regelmäßigen Dokumentenaktualisierung möchten wir Sie bitten, Ihre bei uns hinterlegten Versicherungsdaten zu überprüfen.</p>
    <p style="color: #555; font-size: 16px;">Falls es seit Ihrer letzten Bestätigung Änderungen in Ihren Daten gegeben hat, teilen Sie uns diese bitte per E-Mail an <a href="mailto:office@mac-versicherung.at" style="color: #007BFF;">office@mac-versicherung.at</a> mit.</p>
    <p style="color: #555; font-size: 16px;">Sollten Ihre Daten unverändert sein, bitten wir Sie, die Datenbestätigung zu unterschreiben. Klicken Sie dazu bitte auf den folgenden Button:</p>
    <a href="${url}" style="display: inline-block; padding: 10px 20px; color: white; background-color: #007BFF; text-decoration: none; border-radius: 4px; margin-top: 20px; font-weight: bold;">Daten bestätigen</a>
    <p style="color: #555; font-size: 16px;">Ihre Rückmeldung ist für die Aufrechterhaltung Ihres Versicherungsschutzes sehr wichtig.</p>
    <p style="color: #555; font-size: 16px;">Vielen Dank für Ihre Mitarbeit.</p>
    <p style="color: #555; font-size: 16px;">Mit freundlichen Grüßen,</p>
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