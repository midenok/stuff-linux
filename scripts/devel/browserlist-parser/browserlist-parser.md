# Source
https://github.com/midenok/linux/blob/master/scripts/devel/browserlist-parser/browserlist-parser.pl

# Usage examples

First, get `list_of_all_browsers.html` with command:
`wget http://www.useragentstring.com/pages/Browserlist/ -O list_of_all_browsers.html`

#### Non-unique groups: `--non-unique`, `--nu`

For each group find all groups that have entrances into this group (i.e. browsers that try to disguie as this browser)

```
$ ./browserlist-parser.pl -i list_of_all_browsers.html --nu
$VAR1 = {
          'Avant Browser' => {
                               'Crazy Browser' => 'ARRAY(0x2a69ba0)'
                             },
          'Mozilla' => {
                         'Epiphany' => 'ARRAY(0x263f1a0)',
                         'AOL' => 'ARRAY(0x2a25008)',
                         'Netscape' => 'ARRAY(0x2a25e48)',
                         'Beonex' => 'ARRAY(0x2a2b338)',
                         'Chimera' => 'ARRAY(0x2a2b398)',
                         'Oregano' => 'ARRAY(0x2a2b470)',
                         'osb-browser' => 'ARRAY(0x2a2b4d0)',
                         'K-Ninja' => 'ARRAY(0x2a2b518)',
                         'Galeon' => 'ARRAY(0x2a2b5f0)',
                         'Conkeror' => 'ARRAY(0x2a2ba40)',
                         'Palemoon' => 'ARRAY(0x2a2bad0)',
                         'Kapiko' => 'ARRAY(0x2a2bcf8)',
                         'Iceweasel' => 'ARRAY(0x2a2bd58)',
                         'BonEcho' => 'ARRAY(0x2a29d10)',
                         'iRider' => 'ARRAY(0x2a2e590)',
                         'Element Browser' => 'ARRAY(0x2a2e5f0)',
                         'Camino' => 'ARRAY(0x2a2e638)',
                         'Sundance' => 'ARRAY(0x2a2ec68)',
                         'Kazehakase' => 'ARRAY(0x2a2ecf8)',
                         'Arora' => 'ARRAY(0x2a2f788)',
                         'myibrow' => 'ARRAY(0x2a2f728)',
                         'Wyzo' => 'ARRAY(0x2a2f5d8)',
                         'Avant Browser' => 'ARRAY(0x2a2fbf0)',
                         'DeskBrowse' => 'ARRAY(0x2a2fe00)',
                         'Safari' => 'ARRAY(0x2a2fe48)',
                         'Firefox' => 'ARRAY(0x2a334e8)',
                         'Crazy Browser' => 'ARRAY(0x2a45c50)',
                         'KMLite' => 'ARRAY(0x2a46100)',
                         'Shiira' => 'ARRAY(0x2a46160)',
                         'OmniWeb' => 'ARRAY(0x2a463e8)',
                         'Minefield' => 'ARRAY(0x2a46710)',
                         'Lorentz' => 'ARRAY(0x2a480d8)',
                         'lolifox' => 'ARRAY(0x2a4c190)',
                         'SeaMonkey' => 'ARRAY(0x2a48120)',
                         'Classilla' => 'ARRAY(0x2a4c908)',
                         'QtWeb Internet Browser' => 'ARRAY(0x2a4c7d0)',
                         'Shiretoko' => 'ARRAY(0x2a4c280)',
                         'Konqueror' => 'ARRAY(0x2a4ca88)',
                         'Sunrise' => 'ARRAY(0x2a4c968)',
                         'Phoenix' => 'ARRAY(0x2a50798)',
                         'TencentTraveler' => 'ARRAY(0x2a505b8)',
                         'Sylera' => 'ARRAY(0x2a509a8)',
                         'ABrowse' => 'ARRAY(0x2a50a50)',
                         'Acoo Browser' => 'ARRAY(0x2a50ab0)',
                         'Fireweb Navigator' => 'ARRAY(0x2a51078)',
                         'Iceape' => 'ARRAY(0x2a50e50)',
                         'TheWorld' => 'ARRAY(0x2a50c18)',
                         'Lobo' => 'ARRAY(0x2a510c0)',
                         'TenFourFox' => 'ARRAY(0x2a51180)',
                         'Maxthon' => 'ARRAY(0x2a511e0)',
                         'Namoroka' => 'ARRAY(0x2a51618)',
                         'EnigmaFox' => 'ARRAY(0x2a51d30)',
                         'CometBird' => 'ARRAY(0x2a51d78)',
                         'Vonkeror' => 'ARRAY(0x2a51dd8)',
                         'MyIE2' => 'ARRAY(0x2a51e20)',
                         'Lunascape' => 'ARRAY(0x2a52030)',
                         'Firebird' => 'ARRAY(0x2a52c60)',
                         'Fluid' => 'ARRAY(0x2a53830)',
                         'Cheshire' => 'ARRAY(0x2a538c0)',
                         'Deepnet Explorer' => 'ARRAY(0x2a539e0)',
                         'Iron' => 'ARRAY(0x2a53b00)',
                         'MSIE' => 'ARRAY(0x2a54ed0)',
                         'Madfox' => 'ARRAY(0x2a56dc0)',
                         'Browzar' => 'ARRAY(0x2a56e38)',
                         'K-Meleon' => 'ARRAY(0x2a58e88)',
                         'Sleipnir' => 'ARRAY(0x2a56e80)',
                         'SlimBrowser' => 'ARRAY(0x2a5ae68)',
                         'Orca' => 'ARRAY(0x2a5aee0)',
                         'Hana' => 'ARRAY(0x2a5afa0)',
                         'Comodo_Dragon' => 'ARRAY(0x2a5b018)',
                         'iCab' => 'ARRAY(0x2a5b0c0)',
                         'ChromePlus' => 'ARRAY(0x2a5b258)',
                         'iNet Browser' => 'ARRAY(0x2a5b4b0)',
                         'Flock' => 'ARRAY(0x2a5b510)',
                         'Pogo' => 'ARRAY(0x2a5c570)',
                         'LeechCraft' => 'ARRAY(0x2a5c5b8)',
                         'RockMelt' => 'ARRAY(0x2a5c618)',
                         'KKman' => 'ARRAY(0x2a5cde0)',
                         'IceCat' => 'ARRAY(0x2a5cc78)',
                         'GranParadiso' => 'ARRAY(0x2a5d8b8)',
                         'rekonq' => 'ARRAY(0x2a5d218)',
                         'Charon' => 'ARRAY(0x2a5ddb0)',
                         'Stainless' => 'ARRAY(0x2a5dca8)',
                         'IBrowse' => 'ARRAY(0x2a60e68)',
                         'Chrome' => 'ARRAY(0x2a5ddf8)',
                         'Navscape' => 'ARRAY(0x2a60ec8)',
                         'Opera' => 'ARRAY(0x2a60f58)',
                         'NetPositive' => 'ARRAY(0x2a67740)',
                         'GreenBrowser' => 'ARRAY(0x2a68b40)',
                         'Midori' => 'ARRAY(0x2a677b8)',
                         'WeltweitimnetzBrowser' => 'ARRAY(0x2a68d50)',
                         'NetNewsWire' => 'ARRAY(0x2a68dc8)',
                         'Escape' => 'ARRAY(0x2a68f00)',
                         'Prism' => 'ARRAY(0x2a68f48)',
                         'America Online Browser' => 'ARRAY(0x2a68ff0)'
                       },
          'Maxthon' => {
                         'Acoo Browser' => 'ARRAY(0x2a78750)'
                       },
          'SeaMonkey' => {
                           'Sylera' => 'ARRAY(0x2a78678)'
                         },
          'Epiphany' => {
                          'BonEcho' => 'ARRAY(0x263f128)'
                        },
          'Firefox' => {
                         'Flock' => 'ARRAY(0x2a770c8)',
                         'TenFourFox' => 'ARRAY(0x2a76b60)',
                         'Epiphany' => 'ARRAY(0x2a71740)',
                         'Pogo' => 'ARRAY(0x2a779f8)',
                         'Namoroka' => 'ARRAY(0x2a76be8)',
                         'CometBird' => 'ARRAY(0x2a76c30)',
                         'IceCat' => 'ARRAY(0x2a77a40)',
                         'Netscape' => 'ARRAY(0x2a71a70)',
                         'Minefield' => 'ARRAY(0x2a767b8)',
                         'Lunascape' => 'ARRAY(0x2a76c90)',
                         'Madfox' => 'ARRAY(0x2a76f90)',
                         'Galeon' => 'ARRAY(0x2a75df8)',
                         'Opera' => 'ARRAY(0x2a77ad0)',
                         'SeaMonkey' => 'ARRAY(0x2a76818)',
                         'lolifox' => 'ARRAY(0x2a76ad0)',
                         'Classilla' => 'ARRAY(0x2a76b18)',
                         'Palemoon' => 'ARRAY(0x2a75e70)',
                         'Midori' => 'ARRAY(0x2a78570)',
                         'Orca' => 'ARRAY(0x2a77008)',
                         'Iceweasel' => 'ARRAY(0x2a760b0)',
                         'Kapiko' => 'ARRAY(0x2a76050)',
                         'Camino' => 'ARRAY(0x2a76470)',
                         'Prism' => 'ARRAY(0x2a78600)',
                         'Kazehakase' => 'ARRAY(0x2a765d8)',
                         'Wyzo' => 'ARRAY(0x2a76620)',
                         'myibrow' => 'ARRAY(0x2a76770)'
                       },
          'Safari' => {
                        'Flock' => 'ARRAY(0x2a6d2c0)',
                        'DeskBrowse' => 'ARRAY(0x2a6a260)',
                        'Maxthon' => 'ARRAY(0x2a6a830)',
                        'Epiphany' => 'ARRAY(0x2a69c30)',
                        'LeechCraft' => 'ARRAY(0x2a6d350)',
                        'RockMelt' => 'ARRAY(0x2a6d3b0)',
                        'Shiira' => 'ARRAY(0x2a6a2a8)',
                        'OmniWeb' => 'ARRAY(0x2a6a530)',
                        'rekonq' => 'ARRAY(0x2a6da10)',
                        'Fluid' => 'ARRAY(0x2a6adf8)',
                        'Lunascape' => 'ARRAY(0x2a6abb8)',
                        'Stainless' => 'ARRAY(0x2a6da88)',
                        'Cheshire' => 'ARRAY(0x2a6ae88)',
                        'Iron' => 'ARRAY(0x2a6af90)',
                        'Chrome' => 'ARRAY(0x2a6dfb8)',
                        'Navscape' => 'ARRAY(0x2a71368)',
                        'Surf' => 'ARRAY(0x2a69db0)',
                        'Sunrise' => 'ARRAY(0x2a6a770)',
                        'Midori' => 'ARRAY(0x2a713f8)',
                        'WeltweitimnetzBrowser' => 'ARRAY(0x2a71698)',
                        'Comodo_Dragon' => 'ARRAY(0x2a6cf48)',
                        'iCab' => 'ARRAY(0x2a6cff0)',
                        'ChromePlus' => 'ARRAY(0x2a6d068)',
                        'Arora' => 'ARRAY(0x2a69df8)'
                      },
          'Surf' => {
                      'NetSurf' => 'ARRAY(0x2a69230)'
                    },
          'Links' => {
                       'Elinks' => 'ARRAY(0x2a69368)'
                     },
          'MyIE2' => {
                       'Crazy Browser' => 'ARRAY(0x2a787c8)'
                     },
          'MSIE' => {
                      'Avant Browser' => 'ARRAY(0x2a79fc0)',
                      'Maxthon' => 'ARRAY(0x2a7b4c0)',
                      'AOL' => 'ARRAY(0x2a78840)',
                      'Crazy Browser' => 'ARRAY(0x2a7a1d0)',
                      'KKman' => 'ARRAY(0x2a7d610)',
                      'Lunascape' => 'ARRAY(0x2a7bad8)',
                      'MyIE2' => 'ARRAY(0x2a7b8c8)',
                      'Deepnet Explorer' => 'ARRAY(0x2a7c228)',
                      'Browzar' => 'ARRAY(0x2a7cd70)',
                      'Opera' => 'ARRAY(0x2a7da48)',
                      'Sleipnir' => 'ARRAY(0x2a7cdb8)',
                      'Surf' => 'ARRAY(0x2a79f18)',
                      'SlimBrowser' => 'ARRAY(0x2a7d598)',
                      'GreenBrowser' => 'ARRAY(0x2a815c0)',
                      'TencentTraveler' => 'ARRAY(0x2a7a680)',
                      'Acoo Browser' => 'ARRAY(0x2a7a860)',
                      'iRider' => 'ARRAY(0x2a79f60)',
                      'Escape' => 'ARRAY(0x2a817d0)',
                      'TheWorld' => 'ARRAY(0x2a7a9c8)',
                      'America Online Browser' => 'ARRAY(0x2a81818)',
                      'Lobo' => 'ARRAY(0x2a7b400)'
                    },
          'Chrome' => {
                        'Flock' => 'ARRAY(0x2a82db0)',
                        'Comodo_Dragon' => 'ARRAY(0x2a82ab0)',
                        'ChromePlus' => 'ARRAY(0x2a82b58)',
                        'Iron' => 'ARRAY(0x2a81a58)',
                        'RockMelt' => 'ARRAY(0x2a82e40)'
                      }
        };
```

#### Problematic groups: `--problematic`

These groups break some predefined parsing rules.

```
$ ./browserlist-parser.pl -i list_of_all_browsers.html --problematic
Following groups has not even one entry in its UA strings:

Following groups has some UA strings, where they have no entry:
IceCat
Netscape
Safari
Palemoon

Following groups has problematic version delimiters:
Avant Browser(; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0))
Maxthon(; SV1; .NET CLR 1.1.4322; .NET CLR 2.4.84947; SLCC1; Media Center PC 4.0; Zune 3.5; Tablet PC 3.5; InfoPath.3))
Safari(/)
Firefox()
OmniWeb()
Lunascape( )
MyIE2(; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0))
Charon(; Inferno))
Uzbl()
Iron()
Browzar())
epiphany-browser()
Enigma Browser()
Opera()
SeaMonkey()
SlimBrowser())
GreenBrowser())
midori()
Iceweasel())
epiphany-webkit()
Acoo Browser(; GTB5; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; Maxthon; InfoPath.1; .NET CLR 3.5.30729; .NET CLR 3.0.30618))
TheWorld())

Following groups has no version delimiters:
Netscape(6/6.2.3)
KKman(3.0; .NET CLR 1.1.4322))
KKMAN(3.2; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.2; .NET4.0C))
Firefox(3.6 (.NET CLR 3.5.30729))
Kazehakase(0.4.5)

Following groups has versions that start not from digit:
NavscapeNavigator(/Pre-0.1 Safari/534.12)
TenFourFox(/G3)
LeechCraft( (X11; U; Linux; ru_RU) (LeechCraft/Poshuku 0.3.95-1-g84cc6b7; WebKit 4.7.1/4.7.1))
Firefox( (Debian-2.0.0.19-0etch1))
Shiira( Safari/125)
OmniWeb(/v622.8.0.112941)
rekonq( Safari/533.3)
Uzbl( (Webkit 1.3) (Linux i686 [i686]))
Lynx( (textmode))
Chrome(/ Safari/530.5)
Navscape(/Pre-0.2 Safari/533.3)
uzbl( (Webkit 1.1.9) (Linux 2.6.30-ARCH))
Classilla(/CFM)
Elinks( (0.3.2; Linux 2.4.20-13.8 i686))
Iceweasel( Firefox/3.0.7 (Debian-3.0.7-1))
Links( (6.9; Unix 6.9-astral sparc; 80x25))
ELinks( (0.4pre6; Linux 2.2.19ext3 alpha; 80x25))
IBM WebExplorer( /v0.94)
Sundance((Compatible; Windows; U; en-US;) Version/0.9.0.38)

Following groups has unknown version stopper or version length > 20 chars:
ELinks(/0.12~pre2.dfsg0-1ubuntu1 (textmode; Debian; Linux 2.6.28-15-generic x86_64; 207x60-2))
```

#### Final output: `--export-browsers`, `--export-oses`

Produce output, that will be usable in C++ code. The array will be in strict predefined order, where less common browsers (i.e. those that try to disguise as another browsers) will be listed first.

```
$ ./browserlist-parser.pl -i list_of_all_browsers.html --export-browsers --reorder
{SubString("Crazy Browser", 13), 0},
{SubString("Avant Browser", 13), 0},
{SubString("Acoo Browser", 12), 0},
{SubString("Maxthon", 7), BrowserInfo::WITHOUT_VERSION, vl(SubString("MAXTHON", 7))},
{SubString("Sylera", 6), 0},
{SubString("SeaMonkey", 9), 0, vl(SubString("Seamonkey", 9))},
{SubString("BonEcho", 7), 0},
{SubString("Epiphany", 8), 0, vl(SubString("epiphany-browser", 16))(SubString("epiphany-webkit", 15))},
{SubString("MyIE2", 5), 0},
{SubString("NetSurf", 7), 0},
{SubString("Surf", 4), BrowserInfo::WITHOUT_OS},
{SubString("AOL", 3), 0},
{SubString("Netscape", 8), 0},
{SubString("Beonex", 6), 0},
{SubString("Chimera", 7), 0},
{SubString("Oregano", 7), BrowserInfo::WITHOUT_OS},
{SubString("osb-browser", 11), 0},
{SubString("K-Ninja", 7), 0},
{SubString("Galeon", 6), 0},
{SubString("Conkeror", 8), 0, vl(SubString("conkeror", 8))},
{SubString("Palemoon", 8), 0},
{SubString("Kapiko", 6), 0},
{SubString("Iceweasel", 9), 0, vl(SubString("IceWeasel", 9))(SubString("iceweasel", 9))},
{SubString("iRider", 6), 0},
{SubString("Element Browser", 15), 0},
{SubString("Camino", 6), 0},
{SubString("Sundance", 8), 0},
{SubString("Kazehakase", 10), 0},
{SubString("Arora", 5), 0},
{SubString("myibrow", 7), 0},
{SubString("Wyzo", 4), 0},
{SubString("DeskBrowse", 10), 0},
{SubString("Safari", 6), 0},
{SubString("Firefox", 7), 0, vl(SubString("firefox", 7))},
{SubString("KMLite", 6), 0},
{SubString("Shiira", 6), 0},
{SubString("OmniWeb", 7), 0},
{SubString("Minefield", 9), 0},
{SubString("Lorentz", 7), 0},
{SubString("lolifox", 7), 0},
{SubString("Classilla", 9), 0},
{SubString("QtWeb Internet Browser", 22), 0},
{SubString("Shiretoko", 9), 0},
{SubString("Konqueror", 9), 0},
{SubString("Sunrise", 7), 0, vl(SubString("SunriseBrowser", 14))},
{SubString("Phoenix", 7), 0},
{SubString("TencentTraveler", 15), 0},
{SubString("ABrowse", 7), 0},
{SubString("Fireweb Navigator", 17), 0},
{SubString("Iceape", 6), 0},
{SubString("TheWorld", 8), 0},
{SubString("Lobo", 4), 0},
{SubString("TenFourFox", 10), BrowserInfo::WITHOUT_VERSION},
{SubString("Namoroka", 8), 0},
{SubString("EnigmaFox", 9), 0},
{SubString("CometBird", 9), 0},
{SubString("Vonkeror", 8), 0},
{SubString("Lunascape", 9), BrowserInfo::WITHOUT_VERSION},
{SubString("Firebird", 8), 0},
{SubString("Fluid", 5), 0},
{SubString("Cheshire", 8), 0},
{SubString("Deepnet Explorer", 16), 0},
{SubString("Iron", 4), 0},
{SubString("MSIE", 4), 0},
{SubString("Madfox", 6), 0},
{SubString("Browzar", 7), 0},
{SubString("K-Meleon", 8), 0},
{SubString("Sleipnir", 8), 0},
{SubString("SlimBrowser", 11), 0},
{SubString("Orca", 4), 0},
{SubString("Hana", 4), 0},
{SubString("Comodo_Dragon", 13), 0},
{SubString("iCab", 4), 0},
{SubString("ChromePlus", 10), 0},
{SubString("iNet Browser", 12), 0},
{SubString("Flock", 5), 0},
{SubString("Pogo", 4), 0},
{SubString("LeechCraft", 10), 0, vl(SubString("Leechcraft", 10))},
{SubString("RockMelt", 8), 0},
{SubString("KKman", 5), 0, vl(SubString("KKMAN", 5))},
{SubString("IceCat", 6), 0},
{SubString("GranParadiso", 12), 0},
{SubString("rekonq", 6), 0},
{SubString("Charon", 6), BrowserInfo::WITHOUT_OS},
{SubString("Stainless", 9), 0},
{SubString("IBrowse", 7), 0},
{SubString("Chrome", 6), 0},
{SubString("Navscape", 8), 0, vl(SubString("NavscapeNavigator", 17))},
{SubString("Opera", 5), 0},
{SubString("NetPositive", 11), 0},
{SubString("GreenBrowser", 12), 0},
{SubString("Midori", 6), 0, vl(SubString("midori", 6))},
{SubString("WeltweitimnetzBrowser", 21), 0},
{SubString("NetNewsWire", 11), 0},
{SubString("Escape", 6), 0},
{SubString("Prism", 5), 0, vl(SubString("prism", 5))},
{SubString("America Online Browser", 22), 0},
{SubString("Mozilla", 7), 0},
{SubString("Elinks", 6), 0, vl(SubString("ELinks", 6))},
{SubString("Links", 5), 0},
{SubString("Dooble", 6), BrowserInfo::WITHOUT_OS},
{SubString("retawq", 6), BrowserInfo::WITHOUT_OS},
{SubString("AmigaVoyager", 12), 0},
{SubString("uzbl", 4), 0, vl(SubString("Uzbl", 4))},
{SubString("Cyberdog", 8), 0},
{SubString("Galaxy", 6), 0},
{SubString("w3m", 3), 0},
{SubString("NCSA_Mosaic", 11), 0, vl(SubString("NCSA Mosaic", 11))},
{SubString("HotJava", 7), BrowserInfo::WITHOUT_OS},
{SubString("Lynx", 4), BrowserInfo::WITHOUT_OS},
{SubString("Enigma Browser", 14), BrowserInfo::WITHOUT_OS},
{SubString("Vimprobable", 11), BrowserInfo::WITHOUT_OS},
{SubString("Dillo", 5), BrowserInfo::WITHOUT_OS},
{SubString("IBM WebExplorer", 15), BrowserInfo::WITHOUT_OS},
```
