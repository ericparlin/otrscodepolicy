# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package TidyAll::Plugin::OTRS::SOPM::RequiredElements;

use strict;
use warnings;

use base qw(TidyAll::Plugin::OTRS::Base);

sub transform_source {    ## no critic
    my ( $Self, $Code ) = @_;

    return $Code if $Self->IsPluginDisabled( Code => $Code );

    # Replace OTRS GmbH with OTRS AG
    $Code =~ s{ OTRS [ ]+ GmbH }{OTRS AG}xmsg;

    # Replace Version
    $Code =~ s{ <Version> [^<>\n]* <\/Version> }{<Version>0.0.0</Version>}xmsg;

    # cleanup file tags
    $Code =~ s{ "\/> }{" \/>}xmsg;
    $Code =~ s{ "><\/File> }{" \/>}xmsg;
    $Code =~ s{
        ^ ( [ ]* <File ) [ ]+ ( Location=" [^ <>\n]+ " ) [ ]+ ( Permission="\d\d\d" ) [ ]+ ( \/> )
    }{$1 $3 $2 $4}xmsg;

    # Remove BuildHost and BuildDate tags
    $Code =~ s{ <BuildHost> [^<>\n]* <\/BuildHost> }{}xmsg;
    $Code =~ s{ <BuildDate> [^<>\n]* <\/BuildDate> }{}xmsg;

    # Remove ChangeLog tags
    $Code =~ s{ <ChangeLog> [^<>\n]* <\/ChangeLog> }{}xmsg;

    return $Code;
}

sub validate_source {    ## no critic
    my ( $Self, $Code ) = @_;

    return if $Self->IsPluginDisabled( Code => $Code );

    my $ErrorMessage;

    my $Name            = 0;
    my $Version         = 0;
    my $Counter         = 0;
    my $Framework       = 0;
    my $Vendor          = 0;
    my $URL             = 0;
    my $License         = 0;
    my $BuildDate       = 0;
    my $BuildHost       = 0;
    my $DescriptionDE   = 0;
    my $DescriptionEN   = 0;
    my $Table           = 0;
    my $DatabaseUpgrade = 0;
    my $NameLength      = 0;

    my $TableNameLength = 30;

    my @CodeLines = split /\n/, $Code;

    for my $Line (@CodeLines) {
        $Counter++;
        if ( $Line =~ /<Name>[^<>]+<\/Name>/ ) {
            $Name = 1;
        }
        elsif ( $Line =~ /<Description Lang="en">[^<>]+<\/Description>/ ) {
            $DescriptionEN = 1;
        }
        elsif ( $Line =~ /<Description Lang="de">[^<>]+<\/Description>/ ) {
            $DescriptionDE = 1;
        }
        elsif ( $Line =~ /<License>([^<>]+)<\/License>/ ) {
            $License = 1;
        }
        elsif ( $Line =~ /<URL>([^<>]+)<\/URL>/ ) {
            $URL = 1;
        }
        elsif ( $Line =~ /<BuildHost>[^<>]*<\/BuildHost>/ ) {
            $BuildHost = 1;
        }
        elsif ( $Line =~ /<BuildDate>[^<>]*<\/BuildDate>/ ) {
            $BuildDate = 1;
        }
        elsif ( $Line =~ /<Vendor>([^<>]+)<\/Vendor>/ ) {
            $Vendor = 1;
        }
        elsif ( $Line =~ m{ <Framework (?: [ ]+ [^<>]* )? > ( [^<>]+ ) <\/Framework> }xms ) {
            $Framework = 1;

            my $Version = $1;

            if ( $Version !~ m{ \d+ \. \d+ \. [x\d]+ }xms ) {
                $ErrorMessage .= "Version needs to have the format 0.0.x or 0.0.0!\n";
            }
        }
        elsif ( $Line =~ /<Version>([^<>]+)<\/Version>/ ) {
            $Version = 1;
        }
        elsif ( $Line =~ /<File([^<>]+)>([^<>]*)<\/File>/ ) {
            my $Attributes = $1;
            my $Content    = $2;
            if ( $Content ne '' ) {
                $ErrorMessage .= "Don't insert something between <File><\/File>!\n";
            }
            if ( $Attributes =~ /(Type|Encode)=/ ) {
                $ErrorMessage .= "Don't use the attribute 'Type' or 'Encode' in <File>Tags!\n";
            }
            if ( $Attributes =~ /Location=.+?\.sopm/ ) {
                $ErrorMessage .= "It is senseless to include .sopm-files in a opm! -> $Line";
            }
        }
        elsif ( $Line =~ /(<Table .+?>|<\/Table>)/ ) {
            $Table = 1;
        }
        elsif ( $Line =~ /<DatabaseUpgrade>/ ) {
            $DatabaseUpgrade = 1;
        }
        elsif ( $Line =~ /<\/DatabaseUpgrade>/ ) {
            $DatabaseUpgrade = 0;
        }
        elsif ( $Line =~ /<Table.+?>/ ) {
            if ( $DatabaseUpgrade && $Line =~ /<Table/ && $Line !~ /Version=/ ) {
                $ErrorMessage
                    .= "If you use <Table... in a <DatabaseUpgrade> context you need to have a Version attribute with the beginning version where this change is needed (e. g. <TableAlter Name=\"some_table\" Version=\"1.0.6\">)!\n";
            }
        }

        if ( $Line =~ /<(Column.*|TableCreate.*) Name="(.+?)"/ ) {
            $Name = $2;
            if ( length $Name > $TableNameLength ) {
                $NameLength .= "Line $Counter: $Name\n";
            }
        }
    }

    if ($Table) {
        $ErrorMessage
            .= "The Element <Table> is not allowed in sopm-files. Perhaps you mean <TableCreate>!\n";
    }
    if ($BuildDate) {
        $ErrorMessage .= "<BuildDate> no longer used in .sopms!\n";
    }
    if ($BuildHost) {
        $ErrorMessage .= "<BuildHost> no longer used in .sopms!\n";
    }
    if ( !$DescriptionEN ) {
        $ErrorMessage .= "You have forgot to use the element <Description Lang=\"en\">!\n";
    }
    if ( !$Name ) {
        $ErrorMessage .= "You have forgot to use the element <Name>!\n";
    }
    if ( !$Version ) {
        $ErrorMessage .= "You have forgot to use the element <Version>!\n";
    }
    if ( !$Framework ) {
        $ErrorMessage .= "You have forgot to use the element <Framework>!\n";
    }
    if ( !$Vendor ) {
        $ErrorMessage .= "You have forgot to use the element <Vendor>!\n";
    }
    if ( !$URL ) {
        $ErrorMessage .= "You have forgot to use the element <URL>!\n";
    }
    if ( !$License ) {
        $ErrorMessage .= "You have forgot to use the element <License>!\n";
    }
    if ($NameLength) {
        $ErrorMessage
            .= "Please use Column and Tablenames with less than $TableNameLength letters!\n";
        $ErrorMessage .= $NameLength;
    }
    if ($ErrorMessage) {
        die __PACKAGE__ . "\n" . $ErrorMessage;
    }

    return;
}

1;
