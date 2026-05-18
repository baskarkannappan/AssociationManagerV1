-- Update 'contact-us-details' to our refined, stunning light theme template
UPDATE [corp].[StaticContent]
SET [Title] = 'Support Channels',
    [HtmlContent] = N'<div class="sidebar-wrapper">
    <div class="sidebar-header">
        <h4 class="sidebar-title">Support Channels</h4>
        <p class="sidebar-subtitle">Get in touch directly with our support specialists.</p>
    </div>

    <div class="contact-channels">
        <div class="channel-card">
            <div class="channel-icon icon-email"><i class="bi bi-envelope-at-fill"></i></div>
            <div class="channel-info">
                <span class="channel-label">Email Support</span>
                <a href="mailto:support@platform.com" class="channel-value">support@platform.com</a>
            </div>
        </div>

        <div class="channel-card">
            <div class="channel-icon icon-phone"><i class="bi bi-phone-fill"></i></div>
            <div class="channel-info">
                <span class="channel-label">Direct Support Line</span>
                <span class="channel-value">+1 (800) 555-0199</span>
            </div>
        </div>

        <div class="channel-card">
            <div class="channel-icon icon-web"><i class="bi bi-globe2"></i></div>
            <div class="channel-info">
                <span class="channel-label">Official Website</span>
                <a href="https://www.platform.com" target="_blank" class="channel-value">www.platform.com</a>
            </div>
        </div>

        <div class="channel-card">
            <div class="channel-icon icon-hours"><i class="bi bi-clock-history"></i></div>
            <div class="channel-info">
                <span class="channel-label">Support Hours</span>
                <span class="channel-value">Mon – Fri, 9:00 AM – 6:00 PM EST</span>
            </div>
        </div>
    </div>

    <div class="address-box">
        <h5 class="address-title"><i class="bi bi-geo-alt-fill me-2 icon-pin"></i>Headquarters</h5>
        <div class="address-details">
            <p class="company-name">Corporate Manager Inc.</p>
            <p>100 Innovation Parkway, Suite 500</p>
            <p>Silicon Valley, CA 94025</p>
            <p class="country">United States</p>
        </div>
    </div>

    <div class="response-note">
        <i class="bi bi-info-circle-fill me-2"></i> We aim to respond to all inquiries within <span class="highlight-glow">24 to 48 hours</span>.
    </div>
</div>

<style>
    .sidebar-wrapper {
        color: #334155;
        font-family: system-ui, -apple-system, sans-serif;
    }
    .sidebar-header {
        margin-bottom: 2rem;
    }
    .sidebar-title {
        font-size: 1.5rem;
        font-weight: 800;
        letter-spacing: -0.02em;
        margin-bottom: 0.5rem;
        color: #0f172a;
    }
    .sidebar-subtitle {
        font-size: 0.95rem;
        color: #64748b;
        line-height: 1.5;
        margin: 0;
    }
    .contact-channels {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        margin-bottom: 2rem;
    }
    .channel-card {
        display: flex;
        align-items: center;
        gap: 1.25rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 1.15rem;
        transition: all 0.25s ease;
    }
    .channel-card:hover {
        background: #ffffff;
        border-color: #cbd5e1;
        transform: translateY(-2px);
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.04);
    }
    .channel-icon {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 3rem;
        height: 3rem;
        border-radius: 10px;
        font-size: 1.5rem;
        transition: transform 0.2s ease;
    }
    .channel-card:hover .channel-icon {
        transform: scale(1.05);
    }
    
    .icon-email {
        background: rgba(56, 189, 248, 0.12);
        color: #0369a1;
    }
    .icon-phone {
        background: rgba(74, 222, 128, 0.12);
        color: #15803d;
    }
    .icon-web {
        background: rgba(96, 165, 250, 0.12);
        color: #1d4ed8;
    }
    .icon-hours {
        background: rgba(251, 191, 36, 0.12);
        color: #b45309;
    }
    .icon-pin {
        color: #e11d48;
    }

    .channel-info {
        display: flex;
        flex-direction: column;
        gap: 0.15rem;
    }
    .channel-label {
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: #64748b;
        font-weight: 700;
    }
    .channel-value {
        font-size: 1rem;
        font-weight: 600;
        color: #1e293b;
        text-decoration: none;
        transition: color 0.2s ease;
    }
    a.channel-value:hover {
        color: #2563eb;
        text-decoration: underline;
    }
    .address-box {
        background: #f1f5f9;
        border-left: 4px solid #2563eb;
        border-radius: 4px 12px 12px 4px;
        padding: 1.5rem;
        margin-bottom: 2rem;
    }
    .address-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 0.75rem;
        display: flex;
        align-items: center;
    }
    .address-details {
        font-size: 0.95rem;
        line-height: 1.6;
        color: #334155;
    }
    .address-details p {
        margin: 0;
    }
    .company-name {
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 0.25rem !important;
    }
    .country {
        text-transform: uppercase;
        font-size: 0.8rem;
        letter-spacing: 0.05em;
        color: #64748b;
        font-weight: 700;
        margin-top: 0.25rem !important;
    }
    .response-note {
        font-size: 0.9rem;
        color: #1e40af;
        text-align: center;
        background: rgba(37, 99, 235, 0.06);
        border: 1px solid rgba(37, 99, 235, 0.12);
        border-radius: 8px;
        padding: 0.85rem;
        font-weight: 500;
    }
    .highlight-glow {
        color: #2563eb;
        font-weight: 700;
    }
</style>',
    [LastUpdated] = GETUTCDATE()
WHERE [ContentKey] = 'contact-us-details';
