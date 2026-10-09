import * as SibApiV3Sdk from '@getbrevo/brevo';
import { getOtpEmailHtml } from './email-templates.js';

/**
 * Sends an OTP email to a user using Brevo Transactional Email API.
 * 
 * @param {Object} params
 * @param {string} params.toEmail - Recipient email address
 * @param {string} params.otp - 6-digit numeric OTP code
 * @param {string} params.purpose - 'password_reset' or 'email_verification'
 * @returns {Promise<Object>} Brevo API response
 */
export async function sendOtpEmail({ toEmail, otp, purpose }) {
  const apiKey = process.env.BREVO_API_KEY;
  if (!apiKey) {
    throw new Error('BREVO_API_KEY is not configured');
  }

  const senderEmail = process.env.BREVO_SENDER_EMAIL || 'unarmudasir@gmail.com';
  let senderName = process.env.BREVO_SENDER_NAME || 'e commerce app';
  if (senderName.startsWith('"') && senderName.endsWith('"')) {
    senderName = senderName.slice(1, -1);
  }

  const apiInstance = new SibApiV3Sdk.TransactionalEmailsApi();
  apiInstance.setApiKey(SibApiV3Sdk.TransactionalEmailsApiApiKeys.apiKey, apiKey);

  const subject = purpose === 'password_reset'
    ? 'Your Password Reset Code - E-Commerce Store'
    : 'Your Account Verification Code - E-Commerce Store';

  const htmlContent = getOtpEmailHtml({ otp, purpose, expiryMinutes: 5 });

  const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
  sendSmtpEmail.subject = subject;
  sendSmtpEmail.htmlContent = htmlContent;
  sendSmtpEmail.sender = { name: senderName, email: senderEmail };
  sendSmtpEmail.to = [{ email: toEmail }];

  const result = await apiInstance.sendTransacEmail(sendSmtpEmail);
  return result;
}
