-- Update StaticContent templates with highly premium modern designs
-- Content keys: 'about-us', 'contact-us-details', 'rules-regulations'

-- 1. Update 'about-us'
UPDATE [corp].[StaticContent]
SET [Title] = 'About Our Platform',
    [HtmlContent] = N'<div class="about-hero">
    <div class="hero-accent"></div>
    <h1>About Our Platform</h1>
    <p class="hero-subtitle">Empowering communities with seamless connection, reliable governance, and modern management solutions.</p>
</div>

<div class="about-section">
    <div class="about-card intro-card">
        <p>
            Welcome to <span class="highlight">Corporate Manager</span>. We are dedicated to providing 
            reliable and innovative solutions that help residential and commercial associations achieve their goals. 
            Our focus is on <span class="highlight">quality</span>, 
            <span class="highlight">efficiency</span>, and <span class="highlight">customer satisfaction</span>.
        </p>
    </div>
</div>

<div class="values-grid">
    <div class="value-card">
        <div class="value-icon"><i class="bi bi-shield-check"></i></div>
        <h3>Quality First</h3>
        <p>We build robust, high-performance tools that guarantee operational integrity and standard compliance across all management tasks.</p>
    </div>
    <div class="value-card">
        <div class="value-icon"><i class="bi bi-lightning-charge"></i></div>
        <h3>High Efficiency</h3>
        <p>Automate billing, announcements, and operations. Spend less time on administrative overhead and more on community growth.</p>
    </div>
    <div class="value-card">
        <div class="value-icon"><i class="bi bi-heart"></i></div>
        <h3>Customer Success</h3>
        <p>Our dedicated support team works around the clock to ensure you have a seamless experience running your organization.</p>
    </div>
</div>

<div class="features-section">
    <h2>Why Choose Us?</h2>
    <div class="feature-row">
        <div class="feature-item">
            <span class="feature-badge">01</span>
            <h4>Unified Billing</h4>
            <p>Seamless recurring invoice generation and integrated checkout support.</p>
        </div>
        <div class="feature-item">
            <span class="feature-badge">02</span>
            <h4>Real-time Notifications</h4>
            <p>Instant SMS, Email, and Push alerts for maintenance schedules, announcements, and ledger updates.</p>
        </div>
        <div class="feature-item">
            <span class="feature-badge">03</span>
            <h4>Advanced Analytics</h4>
            <p>Complete visibility into cashflows, outstanding dues, and upcoming budgets through interactive charts.</p>
        </div>
    </div>
</div>

<div class="about-footer">
    <p>© 2026 Corporate Manager. All rights reserved. Empowering modern living.</p>
</div>

<style>
    .about-hero {
        position: relative;
        text-align: center;
        padding: 4rem 2rem;
        background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
        color: #ffffff;
        border-radius: 20px;
        margin-bottom: 2.5rem;
        overflow: hidden;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
    }
    .hero-accent {
        position: absolute;
        top: -50%;
        left: -20%;
        width: 140%;
        height: 140%;
        background: radial-gradient(circle, rgba(99, 102, 241, 0.15) 0%, transparent 60%);
        pointer-events: none;
    }
    .about-hero h1 {
        font-size: 2.5rem;
        font-weight: 800;
        margin-bottom: 1rem;
        letter-spacing: -0.025em;
        background: linear-gradient(to right, #ffffff, #cbd5e1);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }
    .hero-subtitle {
        font-size: 1.125rem;
        color: #94a3b8;
        max-width: 600px;
        margin: 0 auto;
        line-height: 1.6;
    }
    .intro-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 2.25rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px -1px rgba(0, 0, 0, 0.02);
        margin-bottom: 2.5rem;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    .intro-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 20px -8px rgba(0, 0, 0, 0.05);
    }
    .intro-card p {
        font-size: 1.2rem;
        line-height: 1.8;
        color: #334155;
        margin: 0;
    }
    .highlight {
        font-weight: 700;
        color: #2563eb;
        background: rgba(37, 99, 235, 0.05);
        padding: 0.2rem 0.5rem;
        border-radius: 6px;
    }
    .values-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: 1.5rem;
        margin-bottom: 3.5rem;
    }
    .value-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 2rem;
        transition: all 0.3s ease;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.01);
    }
    .value-card:hover {
        transform: translateY(-5px);
        border-color: #cbd5e1;
        box-shadow: 0 20px 25px -5px rgba(0,0,0,0.05);
    }
    .value-icon {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 3.5rem;
        height: 3.5rem;
        background: rgba(37, 99, 235, 0.08);
        color: #2563eb;
        border-radius: 12px;
        font-size: 1.75rem;
        margin-bottom: 1.25rem;
    }
    .value-card h3 {
        font-size: 1.25rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 0.75rem;
    }
    .value-card p {
        font-size: 1rem;
        line-height: 1.6;
        color: #475569;
        margin: 0;
    }
    .features-section {
        background: #f8fafc;
        border-radius: 20px;
        padding: 3rem 2rem;
        margin-bottom: 3rem;
        border: 1px solid #f1f5f9;
    }
    .features-section h2 {
        text-align: center;
        font-size: 1.75rem;
        font-weight: 800;
        color: #0f172a;
        margin-bottom: 2.5rem;
    }
    .feature-row {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        gap: 2rem;
    }
    .feature-item {
        position: relative;
        padding-left: 3rem;
    }
    .feature-badge {
        position: absolute;
        left: 0;
        top: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 2rem;
        height: 2rem;
        background: #e2e8f0;
        color: #475569;
        font-weight: 700;
        font-size: 0.875rem;
        border-radius: 50%;
    }
    .feature-item h4 {
        font-size: 1.125rem;
        font-weight: 700;
        color: #0f172a;
        margin-bottom: 0.5rem;
    }
    .feature-item p {
        font-size: 0.95rem;
        line-height: 1.5;
        color: #475569;
        margin: 0;
    }
    .about-footer {
        text-align: center;
        border-top: 1px solid #e2e8f0;
        padding-top: 2rem;
        color: #94a3b8;
        font-size: 0.875rem;
    }
</style>',
    [LastUpdated] = GETUTCDATE()
WHERE [ContentKey] = 'about-us';

-- 2. Update 'contact-us-details'
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

-- 3. Update 'rules-regulations'
UPDATE [corp].[StaticContent]
SET [Title] = 'Rules & Regulations',
    [HtmlContent] = N'<div class="rules-header">
    <div class="header-badge"><i class="bi bi-journal-check"></i> Standard Operating Guidelines</div>
    <h1>Platform Rules & Regulations</h1>
    <p class="header-intro">General terms, standards of conduct, and procedures designed to ensure a safe, efficient, and harmonious platform experience for all users.</p>
</div>

<div class="rules-container">
    <div class="rule-card">
        <div class="rule-card-header">
            <span class="rule-num">01</span>
            <h2>Account Security & General Platform Access</h2>
        </div>
        <div class="rule-card-body">
            <p>Every resident and administrator accounts must be kept secure. Sharing of administrative credentials is strictly prohibited. Users must immediately report any suspected unauthorized access to their respective portal.</p>
            <ul>
                <li>Passwords must meet platform complexity guidelines.</li>
                <li>Accounts are non-transferable and tied to specific tenant identities.</li>
                <li>Session activity logs may be audited for platform security compliance.</li>
            </ul>
        </div>
    </div>

    <div class="rule-card">
        <div class="rule-card-header">
            <span class="rule-num">02</span>
            <h2>Financial Obligations & Billing Timelines</h2>
        </div>
        <div class="rule-card-body">
            <p>Timely fee payments are critical to maintain uninterrupted platform usage and association operations. Maintenance charges, late fees, and specific levies are calculated in accordance with the individual association''s guidelines.</p>
            <ul>
                <li>All recurring fees are generated automatically on the 1st of each billing cycle.</li>
                <li>A standard grace period is applied before late fines are computed automatically.</li>
                <li>Receipts and settlement declarations are stored on-ledger and cannot be retroactively altered.</li>
            </ul>
        </div>
    </div>

    <div class="rule-card">
        <div class="rule-card-header">
            <span class="rule-num">03</span>
            <h2>Community Conduct & Privacy Protection</h2>
        </div>
        <div class="rule-card-body">
            <p>Respect and community integrity are our core principles. Use of platform broadcast tools, announcements, and discussion areas must adhere to standard professional rules.</p>
            <ul>
                <li>No posting of offensive, discriminatory, or harassing content.</li>
                <li>Community-wide alerts must only be broadcasted by designated platform administrators.</li>
                <li>Personal user data, contact details, and occupancy records are private and must not be distributed without consent.</li>
            </ul>
        </div>
    </div>

    <div class="rule-card">
        <div class="rule-card-header">
            <span class="rule-num">04</span>
            <h2>Dispute Resolution & Support</h2>
        </div>
        <div class="rule-card-body">
            <p>For any grievances or functional conflicts regarding billing calculations or association roles, users must use the official portal channels to ensure formal auditing and traceabilities.</p>
            <ul>
                <li>Formal queries must be submitted through the "Contact Us" portal message system.</li>
                <li>Direct billing appeals must include full Ledger Item IDs and Tenant Details.</li>
                <li>System-wide bug submissions should be escalated via our platform support email.</li>
            </ul>
        </div>
    </div>
</div>

<div class="rules-footer">
    <p>Last Updated: May 2026 • Version 1.2.0 • Corporate Manager System Standards</p>
</div>

<style>
    .rules-header {
        text-align: center;
        margin-bottom: 3.5rem;
        padding-bottom: 2rem;
        border-bottom: 1px solid #e2e8f0;
    }
    .header-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        background: rgba(37, 99, 235, 0.08);
        color: #2563eb;
        padding: 0.5rem 1rem;
        border-radius: 30px;
        font-size: 0.85rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        margin-bottom: 1.25rem;
    }
    .rules-header h1 {
        font-size: 2.25rem;
        font-weight: 800;
        color: #0f172a;
        letter-spacing: -0.02em;
        margin-bottom: 1rem;
    }
    .header-intro {
        font-size: 1.1rem;
        line-height: 1.6;
        color: #475569;
        max-width: 700px;
        margin: 0 auto;
    }
    .rules-container {
        display: flex;
        flex-direction: column;
        gap: 2rem;
        margin-bottom: 3.5rem;
    }
    .rule-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px -1px rgba(0, 0, 0, 0.02);
        transition: all 0.3s ease;
        overflow: hidden;
    }
    .rule-card:hover {
        border-color: #cbd5e1;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05);
        transform: translateY(-2px);
    }
    .rule-card-header {
        background: #f8fafc;
        padding: 1.5rem 2rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        gap: 1.25rem;
    }
    .rule-num {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 2.25rem;
        height: 2.25rem;
        background: #2563eb;
        color: #ffffff;
        font-weight: 700;
        font-size: 0.95rem;
        border-radius: 8px;
    }
    .rule-card-header h2 {
        font-size: 1.25rem;
        font-weight: 750;
        color: #0f172a;
        margin: 0;
    }
    .rule-card-body {
        padding: 2rem;
    }
    .rule-card-body p {
        font-size: 1.05rem;
        line-height: 1.65;
        color: #334155;
        margin-bottom: 1.25rem;
    }
    .rule-card-body ul {
        list-style-type: none;
        padding-left: 0;
        margin: 0;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }
    .rule-card-body li {
        position: relative;
        padding-left: 1.75rem;
        font-size: 0.975rem;
        line-height: 1.5;
        color: #475569;
    }
    .rule-card-body li::before {
        content: "•";
        color: #2563eb;
        font-size: 1.5rem;
        position: absolute;
        left: 0.5rem;
        top: -0.25rem;
    }
    .rules-footer {
        text-align: center;
        border-top: 1px solid #e2e8f0;
        padding-top: 2rem;
        color: #94a3b8;
        font-size: 0.85rem;
    }
</style>',
    [LastUpdated] = GETUTCDATE()
WHERE [ContentKey] = 'rules-regulations';
