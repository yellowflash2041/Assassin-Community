sub vcl_recv {
  # Disallow bot traffic based on user-agent
  if (
    req.http.user-agent ~ "^$"
    || req.http.user-agent ~ "^Java"
    || req.http.user-agent ~ "^Jakarta"
    || req.http.user-agent ~ "IDBot"
    || req.http.user-agent ~ "id-search"
    || req.http.user-agent ~ "User-Agent"
    || req.http.user-agent ~ "compatible ;"
    || req.http.user-agent ~ "ConveraCrawler"
    || req.http.user-agent ~ "^Mozilla$"
    || req.http.user-agent ~ "libwww"
    || req.http.user-agent ~ "lwp-trivial"
    || req.http.user-agent ~ "urllib"
    || req.http.user-agent ~ "GT:WWW"
    || req.http.user-agent ~ "Snoopy"
    || req.http.user-agent ~ "MFC_Tear_Sample"
    || req.http.user-agent ~ "HTTP::Lite"
    || req.http.user-agent ~ "PHPCrawl"
    || req.http.user-agent ~ "URI::Fetch"
    || req.http.user-agent ~ "Zend_Http_Client"
    || req.http.user-agent ~ "http client"
    || req.http.user-agent ~ "PECL::HTTP"
    || req.http.user-agent ~ "panscient.com"
    || req.http.user-agent ~ "IBM EVV"
    || req.http.user-agent ~ "Bork-edition"
    || req.http.user-agent ~ "Fetch API Request"
    || req.http.user-agent ~ "PleaseCrawl"
    || req.http.user-agent ~ "[A-Z][a-z]{3,} [a-z]{4,} [a-z]{4,}"
    || req.http.user-agent ~ "layeredtech.com"
    || req.http.user-agent ~ "WEP Search"
    || req.http.user-agent ~ "Wells Search II"
    || req.http.user-agent ~ "Missigua Locator"
    || req.http.user-agent ~ "ISC Systems iRc Search 2.1"
    || req.http.user-agent ~ "Microsoft URL Control"
    || req.http.user-agent ~ "Indy Library"
    || req.http.user-agent ~ "Fuzz Faster"
    # Spoofed user agent, Firefox 62 was released in Sep 2018, this line added
    # in Dec 2021.
    || (req.http.user-agent ~ "Firefox/62.0" && req.http.user-agent ~ "Win64")
    # DEV gets an order of magnitude more traffic from AhrefsBot than any other
    # search crawler.
    || req.http.user-agent ~ "AhrefsBot"
    || req.http.user-agent == "8484 Boston Project v 1.0"
    || req.http.user-agent == "Atomic_Email_Hunter/4.0"
    || req.http.user-agent == "atSpider/1.0"
    || req.http.user-agent == "autoemailspider"
    || req.http.user-agent == "China Local Browse 2.6"
    || req.http.user-agent == "ContactBot/0.2"
    || req.http.user-agent == "ContentSmartz"
    || req.http.user-agent == "DataCha0s/2.0"
    || req.http.user-agent == "DataCha0s/2.0"
    || req.http.user-agent == "DBrowse 1.4b"
    || req.http.user-agent == "DBrowse 1.4d"
    || req.http.user-agent == "Demo Bot DOT 16b"
    || req.http.user-agent == "Demo Bot Z 16b"
    || req.http.user-agent == "DSurf15a 01"
    || req.http.user-agent == "DSurf15a 71"
    || req.http.user-agent == "DSurf15a 81"
    || req.http.user-agent == "DSurf15a VA"
    || req.http.user-agent == "EBrowse 1.4b"
    || req.http.user-agent == "Educate Search VxB"
    || req.http.user-agent == "EmailSiphon"
    || req.http.user-agent == "EmailWolf 1.00"
    || req.http.user-agent == "ESurf15a 15"
    || req.http.user-agent == "ExtractorPro"
    || req.http.user-agent == "Franklin Locator 1.8"
    || req.http.user-agent == "FSurf15a 01"
    || req.http.user-agent == "Full Web Bot 0416B"
    || req.http.user-agent == "Full Web Bot 0516B"
    || req.http.user-agent == "Full Web Bot 2816B"
    || req.http.user-agent == "Guestbook Auto Submitter"
    || req.http.user-agent == "Industry Program 1.0.x"
    || req.http.user-agent == "ISC Systems iRc Search 2.1"
    || req.http.user-agent == "IUPUI Research Bot v 1.9a"
    || req.http.user-agent == "LARBIN-EXPERIMENTAL (efp@gmx.net)"
    || req.http.user-agent == "LetsCrawl.com/1.0 +http://letscrawl.com/"
    || req.http.user-agent == "Lincoln State Web Browser"
    || req.http.user-agent == "LMQueueBot/0.2"
    || req.http.user-agent == "LWP::Simple/5.803"
    || req.http.user-agent == "Mac Finder 1.0.xx"
    || req.http.user-agent == "MFC Foundation Class Library 4.0"
    || req.http.user-agent == "Microsoft URL Control - 6.00.8xxx"
    || req.http.user-agent == "Missauga Locate 1.0.0"
    || req.http.user-agent == "Missigua Locator 1.9"
    || req.http.user-agent == "Missouri College Browse"
    || req.http.user-agent == "Mizzu Labs 2.2"
    || req.http.user-agent == "Mo College 1.9"
    || req.http.user-agent == "Mozilla/2.0 (compatible; NEWT ActiveX; Win32)"
    || req.http.user-agent == "Mozilla/3.0 (compatible; Indy Library)"
    || req.http.user-agent == "Mozilla/4.0 (compatible; Advanced Email Extractor v2.xx)"
    || req.http.user-agent == "Mozilla/4.0 (compatible; Iplexx Spider/1.0 http://www.iplexx.at)"
    || req.http.user-agent == "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; DTS Agent"
    || req.http.user-agent == "Mozilla/4.0 efp@gmx.net"
    || req.http.user-agent == "Mozilla/5.0 (Version: xxxx Type:xx)"
    || req.http.user-agent == "MVAClient"
    || req.http.user-agent == "NameOfAgent (CMS Spider)"
    || req.http.user-agent == "NASA Search 1.0"
    || req.http.user-agent == "Nsauditor/1.x"
    || req.http.user-agent == "PBrowse 1.4b"
    || req.http.user-agent == "PEval 1.4b"
    || req.http.user-agent == "Poirot"
    || req.http.user-agent == "Port Huron Labs"
    || req.http.user-agent == "Production Bot 0116B"
    || req.http.user-agent == "Production Bot 2016B"
    || req.http.user-agent == "Production Bot DOT 3016B"
    || req.http.user-agent == "Program Shareware 1.0.2"
    || req.http.user-agent == "PSurf15a 11"
    || req.http.user-agent == "PSurf15a 51"
    || req.http.user-agent == "PSurf15a VA"
    || req.http.user-agent == "psycheclone"
    || req.http.user-agent == "RSurf15a 41"
    || req.http.user-agent == "RSurf15a 51"
    || req.http.user-agent == "RSurf15a 81"
    # Block Ruby bots unless they're interacting with the API
    || (req.http.user-agent == "Ruby" && !(req.url ~ "^/api"))
    || req.http.user-agent == "searchbot admin@google.com"
    || req.http.user-agent == "ShablastBot 1.0"
    || req.http.user-agent == "snap.com beta crawler v0"
    || req.http.user-agent == "Snapbot/1.0"
    || req.http.user-agent == "sogou develop spider"
    || req.http.user-agent == "Sogou Orion spider/3.0(+http://www.sogou.com/docs/help/webmasters.htm#07)"
    || req.http.user-agent == "sogou spider"
    || req.http.user-agent == "Sogou web spider/3.0(+http://www.sogou.com/docs/help/webmasters.htm#07)"
    || req.http.user-agent == "sohu agent"
    || req.http.user-agent == "SSurf15a 11"
    || req.http.user-agent == "TSurf15a 11"
    || req.http.user-agent == "Under the Rainbow 2.2"
    || req.http.user-agent == "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"
    || req.http.user-agent == "VadixBot"
    || req.http.user-agent == "WebVulnCrawl.blogspot.com/1.0 libwww-perl/5.803"
    || req.http.user-agent == "Wells Search II"
    || req.http.user-agent == "WEP Search 00"
  ) {
    error 703 "Forbidden Bots";
  }
}

sub vcl_error {
  if (obj.status == 703) {
    set obj.status = 403;
    set obj.response = "Forbidden Bots";
    synthetic {""};
    return (deliver);
  }
}
