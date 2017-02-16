# WordPress-Comment-Overflow
This module exploits a XSS vulnerability found in multiple WordPress versions:
*4.2
*4.1.2
*4.1.1
*3.9.3 

This vulnerability allows an unauthenticated attacker to inject arbitrary JavaScript code into comment fields. The module utilizes administrator authenticated XSS escalation through the WordPress plugin editor to gain remote code execution.


While far from unique, the recent vulnerability in the WordPress 4.2 comment system is exceptionally egregious. The vast majority of WordPress attacks effect user installed plugins. Though these plugins often receive wide usage exploitation of associated vulnerabilities is limited to those users who individually added this content to their site. This vulnerability comes packaged with the default WordPress build.

##WHAT’S THE BIG DEAL?

WordPress is the most popular blogging system in the world, and is used by over 60 million websites. The WordPress Content Management System (CMS) is so popular that it often sees usage on more then just blogs, yes even e-commerce sites. 23.3% of the top 10 million websites are WordPress, and unless these sites disabled the default comment system or installed an alternate comment plugin they are ALL vulnerable.

WordPress released an emergency patch for this vulnerability. If automatic updates are allowed the patch is pushed with 4.1.4. Alternately, upgrading WordPress to version 4.2.2 resolves this issue.
