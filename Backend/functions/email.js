//Email
exports.sendEmail = async function(email, soggetto, testo) {
    const mailOptions = {
        from: "APT <noreply@firebase.com>",
        to: email,
    };

    // The user subscribed to the newsletter.
    mailOptions.subject = soggetto;
    mailOptions.text = testo;
    await mailTransport.sendMail(mailOptions);
    return null;
}