---
sidebar_navigation:
  title: Secure coding guidelines
description: An introduction and description of guidelines for writing secure code at OpenProject and preventing common security vulnerabilities.
keywords: infrastructure, security, coding, guidelines
---



# Secure coding Guidelines

This document provides secure coding development guidelines for developers working on OpenProject. The objective is to help identify and mitigate potential security vulnerabilities early in the development process. This document is based on the best practices following the [Open Web Application Security Project (OWASP)](https://www.owasp.org).

By following these guidelines, developers can contribute to OpenProject while ensuring the security of OpenProject and reduce the risk of vulnerabilities being released into production.

The following guidelines are a starting point for developers interesting in contributing in OpenProject to ensure they are developing secure code. We recommend to refer to the [OWASP cheat sheets](https://cheatsheetseries.owasp.org/) as well as the [OWASP Top Ten](https://owasp.org/www-project-top-ten/) for the most recent and detailed guidelines. The following sections are heavily inspired and cross-referencing the well-known recommendations from the the OWASP, each section providing links for further references to generic, Rails-centered as well as OpenProject-specific information when available.

By adhering to these secure coding development guidelines, contributors to OpenProject can help to significantly reduce the risk of adding potentially unsecure code. Regardless of these guidelines, be mindful when reviewing pull requests of features touching any of these guidelines, keep security in mind whenever you write new code for OpenProject to ensure we deliver a secure and trustworthy software.

The guidelines mentioned below are implemented by OpenProject currently when not specified differently.



## Authentication and Credentials

Implement strong authentication mechanisms for any sensitive credentials to be used in OpenProject. Currently these credentials are one of:

- A user's own login and password for direct logins
- Access tokens for API, OAuth, or external integrations
- Session cookies



**Risks and Impacts**

- *Unauthorized Access:* Attackers could gain unauthorized access on improper authentication mechanisms to protected resources, user accounts, or administrative functions. Resulting consequences are data breaches, unauthorized actions, and potential exposure of sensitive information.
- *Authentication Bypass:* Flaws in authentication logic can permit attackers to bypass the authentication process. Resulting consequences are the same as *Unauthorized Access*.
- *Credential Theft or Stuffing:* Weak authentication methods may lead to attackers stealing user credentials  (e.g., usernames and passwords) or reusing from credentials exploited on other services. Consequences are unauthorized access, account hijacking, and potential misuse of user accounts.
- *Brute Force Attacks:* Insufficient protection against brute force attacks can allow attackers to guess or crack passwords. This could result in account lockouts or takeovers despite otherwise sound mechanisms.
- *Insecure Password Storage*: Storing passwords improperly (e.g., in plaintext or in outdated or incorrectly constructed cryptographic hash functions) can expose them to theft in case of data breaches. This in turn could result in a mass compromise of account data.
- *Insufficient Multi-Factor Authentication (MFA):* Lack of MFA support makes it easier for attackers to compromise accounts with stolen credentials. This results in reduced account security and higher risk of unauthorized access.



**Guidelines**

- Ensure uniqueness and case-insensitivity of user logins.
- Use crytographic hashes for password or credentials storage
- Allow administrators to enforce strong password policies  with a combination of characters, numbers, and special symbols. Implement password expiration and account lockout mechanisms.
- Implement mechanisms to protect against brute force attacks, such as account lockouts, rate limiting, or increasing delays after multiple failed login attempts.
- Use strong password controls and validations
- Provide secure mechanisms for account recovery, such as sending a reset link to the user's registered email address. Avoid leaking the existence of user accounts by always returning the same response.
- Provide means of auditing, maintaining detailed logs of authentication events, including successful and failed login attempts. Log sufficient information for auditing and incident response.
- Use the provided features by Rails to prevent cross-site request forgery (CSRF) attacks by utilizing anti-CSRF tokens for all state-changing requests and ensuring that authentication requests are immune to CSRF.



**Usage at OpenProject**

OpenProject uses industry standard authentication mechanisms that follow the best practices and are the de-facto norm for many organizations:

- External authentication providers using OpenID connect protocols or SAML 2.0 protocol
- External authentication through LDAP user binds, optional LDAP user and group membership synchronization (Enterprise-Edition add-on)
- OAuth 2.0 application authentication and authorization with OpenProject acting as the authorization server. Access tokens are hashed using SHA256 in the database.
- Internal user credential authentication against passwords stored in BCrypt with a high default yet configurable cost factor depending on the organizational requirements.



**References**

https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html

https://guides.rubyonrails.org/security.html



### Session Management

As OpenProject is a web application, the web session is the central mechanism of authentication for users using the application with their browser. A secure session cookie is used to identify a user's active session.

**Risks and Impacts**

- *Session Hijacking:* Attackers may steal or manipulate active user session identifiers, gaining unauthorized access to user accounts or sensitive areas of the application.  Resulting consequences are unauthorized access, data exposure, and potential misuse of user accounts.

- *Session Fixation:* Vulnerabilities that allow session fixation attacks can enable attackers to set a user's session ID and take control of their session. Resulting consequences are unauthorized access, data manipulation, and session theft.

- *Improper Session Timeout:* Inadequate session timeout settings can lead to prolonged active sessions, increasing the window and surface of opportunity for attackers. Resulting consequences are exposure to session-related attacks and unauthorized access.

- *Insecure Session Storage:* Storing session data insecurely (e.g., in client-side storage or without proper care) can expose it to theft or tampering. Potential impacts are unauthorized data access or manipulation, data breaches, and privacy violations.

- *Insufficient Session Revocation:* Lack of proper mechanisms to revoke or terminate user sessions can result in prolonged access for users who should no longer have it. Potential impacts are unauthorized access to protected resources and data.

- *Cross-Site Scripting (XSS) and Session Theft:*  If an application is vulnerable to XSS attacks, attackers can steal session identifiers and impersonate users.

- *Lack of Session Regeneration:* Failure to regenerate session identifiers upon login or privilege changes can expose users to session fixation attacks.

- *Session Data Tampering:* Inadequate session data validation and protection can lead to attackers modifying session attributes to gain unauthorized privileges.

- *Weak Session Tokens:* Weak or predictable session token generation can make it easier for attackers to guess or brute-force session identifiers.

  

**Guidelines**

- Use Rails' built-in secure session cookies for maintaing the users' session. It incorporates best-practices to ensure strong session tokens, tamper resistance, and proper expiration.
- Ensure session cookies are marked `secure` and `httponly`, as well as providing the appropriate `SameSite` and expiry flags according to the instance's configuration.
- Provide a secure logout mechanism that invalidates the session and clears session cookies. Ensure that users are logged out after a period of inactivity.
- Implement session fixation protection mechanisms to prevent attackers from fixing a user's session to a known value.
- Prevent storing sensitive unencrypted session information on the client device
- Allow users to terminate sessions themselves, as well as allow instances to prevent simultaneous session logins by terminating other sessions.
- Implement strong Cross-site scriptiong (XSS) protections as listed further down below, as the target of XSS attacks is often exploitation of the user's session credential.

**References**

https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html



## Authorization and Access Control

At its core, permissions in OpenProject are the central key to determine who can access which projects and modules of an instance, as well as what actions they can perform on these pages. OpenProject application uses a Role-based access control (RBAC) approach to grant individual users permissions to projects. The risks associated with security vulnerabilities in the authorization code can have serious implications for the security.

**Risks and Impact**

- *Unauthorized access*: Users gaining or exploting access to sensitive resources or functionalities they are not supposed to have access to. Potential consequences in data breaches, unauthorized actions, and potential exposure of confidential information.
- *Over-Privileged Users*:  Users receiving more permissions than necessary for their role, leading to potential misuse of privileges. Potential consequencse are unauthorized data modifications, data leaks, or abuse of system capabilities.



**Guidelines**

- Allow flexible assignment of permissions for individual projects and objects, following the *Least Privilege* rule.
- Implement controlls and authorization checks with a *Deny by default* or *Fallback deny* rule, preventing authorization flows to miss certain steps and allowing user requests to fall through the authorization checks.
- Validate the permissions of a user on every request, regardless of the origin of it.
- Enforce proper authorization controls to ensure that users only access their own data.
- Provide extensive tests for permission checks, making assertions of all available cases and using visibility testing for asserting that certain actors _cannot_ access data or perform actions. 
- Regularly review and update access controls to reflect changes in application functionality and roles.



**References**

https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html

https://guides.rubyonrails.org/security.html



## User Input Validation

OpenProject is a form-driven application, meaning that users input a lot of data into the system to use it. Proper validation and encoding of user input is crucial to ensure data can be processed in a responsible way.



**Risks and Impacts**

- *Injection attacks:* Attackers could inject malicious code or payloads into the application, leading to vulnerabilities such as SQL injection, or OS-level command injection. Potential consequences are unauthorized data access, data manipulation, and potentially complete system compromise.
- *Cross-site scripting (XSS)*: Failure to validate and sanitize user inputs can allow malicious scripts to be executed in the context of other users' browsers. Potential consequences are: Theft of sensitive user data, session hijacking, and potential defacement or compromise of the web application.
- *Cross-Site Request Forgery (CSRF):* Lack of proper request validation can make it easier for attackers to trick users into performing unintended actions on their behalf. Potential consequences are unauthorized actions, such as account changes, data deletion, or fund transfers, performed without user consent.
- *File Upload Vulnerabilities*: Insufficient input validation on file uploads can lead to arbitrary file uploads, enabling attackers to upload malicious files or execute code. Potential consequences are remote malware distribution, and remote code execution.



**Guidelines**

- Understand and use the [Rails framework's mechansims](https://guides.rubyonrails.org/security.html#injection) to prevent injection and CSRF attacks
- Understand and use the Rails framework to use its built-in security measures such as proper encoding of HTML output, CSRF tokens in all state-changing requests, and automatic escaping of user input in ActiveRecord SQL queries.
- Implement a strict [content security policy](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html) to mitigate common XSS, CSRF and similar cross-site attack vectors. OpenProject uses the [secure_headers gem](https://github.com/github/secure_headers) to define its CSP.
- Learn about the [different types of XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i) and their impacts: Reflected XSS, Stored XSS, Dom-based XSS and server vs client side XSS
- Implement file upload filters based on file type, and ensure user-provided files cannot be executed as code.
- Ensure transmission of confidential data does not happen through GET requests, but use POST/PUT/PATCH requests instead.

**References**

https://guides.rubyonrails.org/security.html#injection

https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i

https://cheatsheetseries.owasp.org/cheatsheets/Injection_Prevention_Cheat_Sheet.html

https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html



## External dependencies

OpenProject includes a number of external dependencies both in Ruby as well as in the JavaScript ecosystem. Regardless of the selection of these dependencies, maintaining and keeping the dependencies up-to-date is a critical part of the security of the application. We have seen a lot of attacks surface in the past years originating from either outdated or manipulated dependencies.

**Risks**

- *Outdated code or known Vulnerabilities*: Older versions of libraries or dependencies may have publicly disclosed vulnerabilities. If these known vulnerabilities are not patched, they can be readily exploited by attackers.
- *Increased Attack Surface*: Over time, libraries can become bloated with features, some of which may not be needed in OpenProject. This increases the overall attack surface, making the application more vulnerable to potential attacks.
- *Lack of Support*: Outdated libraries may no longer be maintained. This means no more security updates, bug fixes, or support from the developer community.
- *Legacy Code and Deprecated Functions*: Outdated dependencies might utilize functions or methods that have since been deprecated or replaced without OpenProject developers being aware of that fact, leading to unreliable or unsafe code practices.
- *Reduced Performance*: Newer versions of libraries often come with performance improvements. Using outdated dependencies can lead to inefficiencies or bottlenecks in the application.
- *Increased maintenance burden*: With a rising number of dependencies that are outdated or unmaintained, providing a secure upgrade path becomes harder due to e.g., newer versions of Rails or Ruby no longer being compatible with the gem or package in question.
- *Chain of Dependencies*: Some dependencies rely on other dependencies. Using an outdated library might cause a cascading effect where multiple parts of your application become outdated and vulnerable. Also, selection of dependencies is important to minimize attack vectors. Every platform handles this differently.

**Guidelines**

- *Automate Updates*: Use and maintain automated tools such as Dependabot and workflows that check for dependency updates regularly, and run tests when updates are available. Before updating the dependencies, review its changelog or release notes to understand changes and potential impacts on your application.
- *Manual update checking:* For pinned versions, use `npm outdated`, `bundle outdated` or `npm-check-updates `to ensure you staay on top of new versions and see if breaking changes ocurred.
- *Lockfile integrity*: Use `package-lock.json` and `Gemfile.lock` to pin exact version for a released version of OpenProject, ensuring that all environments use the same versions.
- *Stay Informed*: Subscribe to mailing lists, newsletters, or vulnerability databases to receive timely information on crucial updates or security patches so that updates can be performed as fast as possible.
- *Vet new dependencies*: Before adding a new gem or package, research its maintenance history, last update, known vulnerabilities, and community reviews. Check if it's actively maintained, and evaluate all the alternatives.
- *Remove outdated dependencies* :Only include gems and packages that are absolutely necessary for your project. Less dependencies mean a reduced attack surface. Remove libraries if they become unused.



**References**

https://cheatsheetseries.owasp.org/cheatsheets/Vulnerable_Dependency_Management_Cheat_Sheet.html



## Logging and Error Handling

Inconsiderate use of error handling, logging, and monitoring mechanisms of a web frameworks can lead to the following risks and impacts.

**Risks and Impacts**

- *Information Disclosure:* Improper error handling may reveal sensitive information or internal details about the application's infrastructure. Resulting consequences are Exposure of sensitive data, such as database errors or stack traces, which can aid attackers in planning further attacks.
- *Data Leakage:* Inadequate logging and error handling can inadvertently log sensitive user data or credentials. This may result in unauthorized access to user data, privacy violations, and compliance breaches.
- *Log Injection Attacks:* Lack of input validation on log entries can expose the application to log injection attacks where attackers manipulate log entries to inject malicious code or content. Resulting impacts are Malicious code execution, log manipulation, and potential system compromise.

**Guidelines**

- Implement proper exception handling to catch and handle unexpected errors. Log the exceptions for further analysis.
- The application should fail in a secure manner. If an error occurs, the system should revert to a safe state that doesn't expose sensitive information or functionality.
- Use generic error messages for end users to prevent information leakage. Avoid exposing stack traces, database error messages, or any detailed system information. If providing summaries or error reports to users, make sure no sensitive data or system information is included.
- Scrub and filter user data being logged or output in error messages to prevent data leakage.
- Only log necessary information. Avoid logging sensitive data such as passwords, payment information, or Personally Identifiable Information (PII).
- Log data in a standard format to make parsing, auditing, and monitoring of that information easy.
- Ensure that actions are aborted in case of errors



**Usage at OpenProject**

- Exception handlers catch all StandardErrors whenever your controller inherits from ApplicationController
- Exception responses are disconnected from the actual errors and provide user-friendly messages without error details
- Database transaction wrapping for any actions is wrapped in the [BaseContracted services](https://github.com/opf/openproject/blob/dev/app/services/base_services/base_contracted.rb#L54). Transactions are automatically rolled back in [Rails when exceptions occur](https://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Transactions/ClassMethods.html).
- OpenProject uses a LogRage formatter for flexible, yet easily parseable formats



**References**

https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html

https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
