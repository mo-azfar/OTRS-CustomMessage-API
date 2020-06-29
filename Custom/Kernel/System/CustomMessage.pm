# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::CustomMessage;

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

#use Data::Dumper;
#use Fcntl qw(:flock SEEK_END);
use JSON::MaybeXS;
use LWP::UserAgent;
use HTTP::Request::Common;
#yum install -y perl-LWP-Protocol-https
#yum install -y perl-JSON-MaybeXS

our @ObjectDependencies = (
    'Kernel::System::Ticket',
    'Kernel::System::Log',
	'Kernel::System::Group',
	'Kernel::System::Queue',
	'Kernel::System::User',
	
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=cut

		my $Test = $Self->SendMessageTelegramGroup(
			TicketURL => $TicketURL,
			Token    => $Token,
			TelegramGroupChatID  => $TelegramGroupChatID,
			Message      => $Message1,
			TicketID      => $TicketID, #sent for log purpose
			Queue      => $Ticket{Queue}, #sent for log purpose
		);

=cut

sub SendMessageTelegramGroup {
	my ( $Self, %Param ) = @_;

	# check for needed stuff
    for my $Needed (qw(TicketURL Token TelegramGroupChatID Message TicketID Queue)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Missing parameter $Needed!",
            );
            return;
        }
    }

	my $ua = LWP::UserAgent->new;
	utf8::decode($Param{Message});
	my $p = {
			chat_id=>$Param{TelegramGroupChatID},
			parse_mode=>'HTML',
			text=>$Param{Message},
			reply_markup => {
				#resize_keyboard => \1, # \1 = true when JSONified, \0 = false
				inline_keyboard => [
				# Keyboard: row 1
				[
				
				{
                text => 'View',
                url => $Param{TicketURL}
				}
                  
				]
				]
				}
			};
	
	my $response = $ua->request(
		POST "https://api.telegram.org/bot".$Param{Token}."/sendMessage",
		Content_Type    => 'application/json',
		Content         => JSON::MaybeXS::encode_json($p)
       )	;
	
	my $ResponseData = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => $response->decoded_content,
    );
	
	if ($ResponseData->{ok} eq 0)
	{
	$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "Telegram group notification to Queue $Param{Queue} ($Param{TelegramGroupChatID}): $ResponseData->{description}",
		);
	}
	else
	{
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	my $TicketHistory = $TicketObject->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'SendAgentNotification',
        Name         => "Sent Telegram Group Notification for Queue $Param{Queue}",
        CreateUserID => 1,
		);			
	}
}

=cut

		my $Test = $Self->SendMessageSlack(
						SlackWebhookURL	=>	$SlackWebhookURL,
						TicketURL	=>	$TicketURL,
						TicketNumber	=>	$Ticket{TicketNumber},
						MessageText	=>	$MessageText1,
						Created	=> $DateTimeString,
						Queue	=> $Ticket{Queue},
						Service	=>	$Ticket{Service},
						Priority=>	$Ticket{Priority},	
						TicketID      => $TicketID, #sent for log purpose
		);

=cut

sub SendMessageSlackChannel {
	my ( $Self, %Param ) = @_;

	# check for needed stuff
    for my $Needed (qw(SlackWebhookURL TicketURL TicketNumber MessageText Created Queue Service Priority TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Missing parameter $Needed!",
            );
            return;
        }
    }
	
	my $ua = LWP::UserAgent->new;
	utf8::decode($Param{MessageText});
	
	my $params = {
       "blocks"=> [
	{
		"type" => "section",
		"text" => {
			"type" => "mrkdwn",
			"text" => "*<$Param{TicketURL}|OTRS#$Param{TicketNumber}>*\n\n$Param{MessageText}"
		}
	},
	{
		"type" => "section",
		"fields" => [
			{
				"type" => "mrkdwn",
				"text" => "*Created:*\n$Param{Created}"
			},
			{
				"type" => "mrkdwn",
				"text" => "*Queue:*\n$Param{Queue}"
			},
			{
				"type" => "mrkdwn",
				"text" => "*Service:*\n$Param{Service}"
			},
			{
				"type" => "mrkdwn",
				"text" => "*Priority:*\n$Param{Priority}"
			}
		]
	}
	]
	};
		  
	my $response = $ua->request(
		POST $Param{SlackWebhookURL},
		Content_Type    => 'application/json',
		Content         => JSON::MaybeXS::encode_json($params)
	)	;
	
	my $content  = $response->decoded_content();
	my $resCode =$response->code();

	if ($resCode ne 200)
	{
	$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "Slack notification for Queue $Param{Queue}: $resCode $content",
		);
	}
	else
	{
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	my $TicketHistory = $TicketObject->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'SendAgentNotification',
        Name         => "Sent Slack Notification for Queue $Param{Queue}",
        CreateUserID => 1,
		);			
	}
}

=cut

		my $Test = $Self->SendMessageRC(
					Channel	=>	$Channel,
					RCURL	=>	$RC_URL,
					TicketURL	=>	$TicketURL,
					TicketNumber	=>	$Ticket{TicketNumber},
					Message	=>	$Message1,
					Created	=> $DateTimeString,
					Queue	=> $Ticket{Queue},
					State	=>	$Ticket{State},	
					TicketID      => $TicketID, #sent for log purpose
		);

=cut

sub SendMessageRCChannel {
	my ( $Self, %Param ) = @_;

	# check for needed stuff
    for my $Needed (qw(Channel RCURL TicketURL TicketNumber Message Created Queue State TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Missing parameter $Needed!",
            );
            return;
        }
    }
	
	my $ua = LWP::UserAgent->new;
	utf8::decode($Param{Message});
	
	my $params = {
	'username'   => 'OTRS Bot',
	'text'      => $Param{Message},  ##for mention specific user, use \@username in message portion
	'channel'	=> $Param{Channel},
	##'channel[0]'	=> '@maba',  ##for direct message to user
	##'channel[1]'	=> '@maba2', ##for direct message to user 2
	'attachments[0][title]'	=> "Ticket#$Param{TicketNumber}",
	'attachments[0][text]'	=> "Create : $Param{Created}\nQueue : $Param{Queue}\nState : $Param{State}",
	'attachments[1][title]'	=> 'View Ticket',
	'attachments[1][title_link]'	=> $Param{TicketURL},
	'attachments[1][text]'	=> 'Go To The Ticket',	  
	};
	
	#$ua->ssl_opts(verify_hostname => 0); # be tolerant to self-signed certificates
	my $response = $ua->post( $Param{RCURL}, $params );
	
	my $content  = $response->decoded_content();
	my $resCode =$response->code();
	
	if ($resCode ne 200)
	{
	$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "RocketChat notification for Queue $Param{Queue}: $resCode $content",
		);
	}
	else
	{
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	my $TicketHistory = $TicketObject->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'SendAgentNotification',
        Name         => "Sent RocketChat Notification for Queue $Param{Queue}",
        CreateUserID => 1,
		);			
	}
}

=cut

		my $Test = $Self->SendMessageTeams(
				MSTeamWebhookURL	=>	$MSTeamWebhookURL,
				MessageSubject	=>	$MessageSubject,
				MessageText	=>	$MessageText1,
				TicketNumber	=>	$Ticket{TicketNumber},
				Created	=> $DateTimeString,
				Queue	=> $Ticket{Queue},
				Service	=>	$Ticket{Service},
				Priority=>	$Ticket{Priority},
				TicketURL	=>	$TicketURL,
				TicketID      => $TicketID, #sent for log purpose
		);

=cut

sub SendMessageMSTeams {
	my ( $Self, %Param ) = @_;

	# check for needed stuff
    for my $Needed (qw(MSTeamWebhookURL MessageSubject MessageText TicketNumber Created Queue Service Priority TicketURL TicketID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Missing parameter $Needed!",
            );
            return;
        }
    }
	
	my $ua = LWP::UserAgent->new;
	utf8::decode($Param{MessageText});
			
	my $params = {
	    "\@context"  => "https://schema.org/extensions",
		"\@type" => "MessageCard",
		"themeColor"=> "0072C6",
		"summary"=> "Ticket Info",
		"sections"=> [{
		"activityTitle"=> $Param{MessageSubject},
		"activitySubtitle"=> "Ticket Details for OTRS#$Param{TicketNumber}",
        "activityImage"=> "http://icons.iconarchive.com/icons/artua/star-wars/256/Clone-Trooper-icon.png",
		    "text"=> $Param{MessageText},
            "facts"=> [
			{ 
				"name"=> "Create", 
				"value"=> $Param{Created} 
			},
			{ 
				"name"=> "Queue", 
				"value"=> $Param{Queue} 
			}, 
			{ 
				"name"=> "Service", 
				"value"=> $Param{Service} 
			}, 
			{ 
				"name"=> "Priority", 
				"value"=> $Param{Priority} 
			}]
		}],
		"markdown" => "true",
		"potentialAction"=> [{        
				"\@type"=> "OpenUri", 
				"name"=> "View",
                    "targets"=> [{ 
				        "os"=> "default", 
				        "uri"=> $Param{TicketURL}
				        }
            ]
		}
		]
	};     
	
	my $response = $ua->request(
		POST $Param{MSTeamWebhookURL},
		Content_Type    => 'application/json',
		Content         => JSON::MaybeXS::encode_json($params)
	)	;
	
	
	my $content  = $response->decoded_content();
	my $resCode =$response->code();

	if ($resCode ne 200)
	{
	$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "MSTeams notification for Queue $Param{Queue}: $resCode $content",
		);
	}
	else
	{
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	my $TicketHistory = $TicketObject->HistoryAdd(
        TicketID     => $Param{TicketID},
        HistoryType  => 'SendAgentNotification',
        Name         => "Sent MSTeams Notification for Queue $Param{Queue}",
        CreateUserID => 1,
		);			
	}
}

1;
