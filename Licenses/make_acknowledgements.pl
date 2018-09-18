#!/usr/bin/perl -w

use strict;

my $plistout =  "$ENV{SRCROOT}/$ENV{PRODUCT_NAME}/Settings.bundle/Acknowledgements.plist";

open(my $plistfh, '>', $plistout) or die $!;

print $plistfh <<'EOD';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>StringsTable</key>
    <string>Acknowledgements</string>
    <key>PreferenceSpecifiers</key>
    <array>
        <dict>
            <key>Type</key>
            <string>PSGroupSpecifier</string>
            <key>FooterText</key>
            <string>Portions of this software may utilize the following copyrighted material, the use of which is hereby acknowledged:</string>
        </dict>
EOD
for my $i (sort glob("*.license"))
{
    my $value=`cat $i`;
    $value =~ s/\r//g;
    $value =~ s/\n/\r/g;
    $value =~ s/[ \t]+\r/\r/g;
    $value =~ s/&/\&amp;/g;
    $value =~ s/\"/\&quot;/g;
    $value =~ s/</\&lt;/g;
    $value =~ s/>/\&gt;/g;

    my $name = substr($i, 0, -8);
    
    print $plistfh <<"EOD";
        <dict>
            <key>Type</key>
            <string>PSGroupSpecifier</string>
            <key>FooterText</key>
            <string>$name\r$value</string>
        </dict>
EOD
}

print $plistfh <<'EOD';
    </array>
</dict>
</plist>
EOD
close($plistfh);