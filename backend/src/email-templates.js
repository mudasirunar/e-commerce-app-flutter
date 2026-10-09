/**
 * Generates a modern, responsive HTML email for OTP verification.
 * 
 * @param {Object} options
 * @param {string} options.otp - The 6-digit numeric OTP code
 * @param {string} options.purpose - The purpose: 'password_reset' or 'email_verification'
 * @param {number} [options.expiryMinutes=5] - Expiration duration in minutes
 * @returns {string} Fully rendered HTML string
 */
export function getOtpEmailHtml({ otp, purpose, expiryMinutes = 5 }) {
  const isReset = purpose === 'password_reset';
  const title = isReset ? 'Reset Your Password' : 'Verify Your Email';
  const subtitle = isReset
    ? 'We received a request to reset the password for your account. Use the verification code below to proceed.'
    : 'Welcome to our e-commerce platform! Please confirm your email address using the verification code below.';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #FAF8F5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1C1917; -webkit-font-smoothing: antialiased;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #FAF8F5; padding: 40px 16px;">
    <tr>
      <td align="center">
        <!-- Main Container Card -->
        <table role="presentation" width="100%" style="max-width: 520px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px -2px rgba(28, 25, 23, 0.08); border: 1px solid #E7E5E4;">
          
          <!-- Header Banner (Aligned with Palette 2: Warm Earth & Terracotta) -->
          <tr>
            <td style="background: linear-gradient(135deg, #1C1917 0%, #431407 100%); padding: 36px 32px 28px 32px; text-align: center;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                <tr>
                  <td align="center">
                    <div style="display: inline-block; background: rgba(234, 88, 12, 0.15); border: 1px solid rgba(251, 146, 60, 0.35); border-radius: 12px; padding: 8px 16px; margin-bottom: 16px;">
                      <span style="color: #FB923C; font-size: 13px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase;">e commerce app</span>
                    </div>
                    <h1 style="margin: 0; color: #FAF8F5; font-size: 22px; font-weight: 700; letter-spacing: -0.3px;">
                      ${title}
                    </h1>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 36px 32px 24px 32px;">
              <p style="margin: 0 0 18px 0; font-size: 15px; line-height: 1.6; color: #44403C;">
                Hello,
              </p>
              <p style="margin: 0 0 26px 0; font-size: 15px; line-height: 1.6; color: #44403C;">
                ${subtitle}
              </p>

              <!-- OTP Code Display Box -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 28px;">
                <tr>
                  <td align="center">
                    <div style="background-color: #FFF7ED; border: 2px dashed #FDBA74; border-radius: 14px; padding: 22px 16px; text-align: center;">
                      <div style="font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 1.5px; color: #9A3412; margin-bottom: 10px;">
                        Your One-Time Code
                      </div>
                      <div style="font-family: 'Courier New', Courier, monospace; font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #1C1917; text-indent: 10px;">
                        ${otp}
                      </div>
                      <div style="margin-top: 10px; font-size: 13px; color: #C2410C; font-weight: 600;">
                        ⏱ Expires in ${expiryMinutes} minutes
                      </div>
                    </div>
                  </td>
                </tr>
              </table>

              <!-- Security Notice -->
              <div style="background-color: #FFFBEB; border-left: 4px solid #D97706; border-radius: 6px; padding: 14px 16px; margin-bottom: 24px;">
                <p style="margin: 0; font-size: 13px; line-height: 1.5; color: #92400E;">
                  <strong>Security Reminder:</strong> Never share this code with anyone. Our support team will never ask for your verification code.
                </p>
              </div>

              <p style="margin: 0; font-size: 13px; line-height: 1.6; color: #78716C;">
                If you did not initiate this request, you can safely ignore this email. Your account remains secure.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 32px 32px 32px; background-color: #F5F5F4; border-top: 1px solid #E7E5E4; text-align: center;">
              <p style="margin: 0 0 6px 0; font-size: 12px; color: #78716C;">
                &copy; ${new Date().getFullYear()} e commerce app. All rights reserved.
              </p>
              <p style="margin: 0; font-size: 11px; color: #A8A29E;">
                This is an automated security transmission. Please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}
