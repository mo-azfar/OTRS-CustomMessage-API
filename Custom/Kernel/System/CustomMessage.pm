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

		my $Test = $Self->SendMessageTelegramAgent(
                TicketURL => $TicketURL,
				Token    => $Token,
				TelegramAgentChatID  => $RecipientChatIDField,
				Message      => $Notification{Body},
				TicketID      => $TicketID, #sent for log purpose
				ReceiverName      => $UserFullName, #sent for log purpose
		);

=cut

sub SendMessageTelegramAgent {
	my ( $Self, %Param ) = @_;
	
	# check for needed stuff
    for my $Needed (qw(TicketURL Token TelegramAgentChatID Message TicketID ReceiverName)) {
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
			chat_id=>$Param{TelegramAgentChatID},
			parse_mode=>'HTML',
			text=>"$Param{Message}",
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
			 Message  => "Telegram notification to $Param{ReceiverName} ($Param{TelegramAgentChatID}): $ResponseData->{description}",
		);
		return 0;
	}
	else 
	{
		return 1;
	}
}

=cut

		my $Test = $Self->SendMessageSlackAgent(
                Token    => $Token,
				SlackMemberID  => $RecipientMemberID,	
				TicketURL	=>	$TicketURL,
				TicketNumber	=>	$Ticket{TicketNumber},
				Message	=>	$Notification{Body},
				Created	=> $TicketDateTimeString,
				Queue	=> $Ticket{Queue},
				Service	=>	$Ticket{Service},
				Priority=>	$Ticket{Priority},	
				TicketID      => $TicketID, #sent for log purpose
				ReceiverName      => $UserFullName, #sent for log purpose
		);

=cut

sub SendMessageSlackAgent {
	my ( $Self, %Param ) = @_;
	
	# check for needed stuff
    for my $Needed (qw(Token SlackMemberID TicketURL TicketNumber Message Created Queue Service Priority TicketID ReceiverName)) {
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
	
	#https://api.slack.com/methods/conversations.open
	#to get userid based on member id
	my $params1 = {
       "return_im" => "true",
	   "users" => $Param{SlackMemberID},

	};
	
	my $response1 = $ua->post('https://slack.com/api/conversations.open',
    'Content' => JSON::MaybeXS::encode_json($params1),
    'Content-Type' => 'application/json',
    'Authorization' => $Param{Token}
	);
	
	my $content1  = decode_json ($response1->decoded_content());
	my $resCode1 = $response1->code();
	
	if (defined $content1->{error})
	{
	$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "Slack notification to $Param{ReceiverName} ($Param{SlackMemberID}): $content1->{error}",
		);
    return 0;
	}
	
	
	#https://api.slack.com/methods/chat.postMessage
	#send message to userid
	my $params2 = {
       "channel" => $content1->{channel}->{user},
	   "text" => $Param{Message},
	   "blocks"=> [
		{
		"type" => "section",
		"text" => {
			"type" => "mrkdwn",
			"text" => "*<$Param{TicketURL}|$Param{TicketNumber}>*\n\n$Param{Message}"
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
		
	my $response2 = $ua->post('https://slack.com/api/chat.postMessage',
    'Content' => JSON::MaybeXS::encode_json($params2),
    'Content-Type' => 'application/json',
    'Authorization' => $Param{Token}
	);

	my $content2  = decode_json ($response2->decoded_content());
	my $resCode2 = $response2->code();
	
	if (defined $content2->{error})
	{
		$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "Slack notification to $Param{ReceiverName} ($Param{SlackMemberID}): $content2->{error}",
		);
		return 0;
	}
	else 
	{
		return 1;
	}
}

=cut

		my $Test = $Self->SendMessageRCAgent(
					Channel	=>	$RecipientUsername,
					WebhookURL	=>	$WebhookURL,
					TicketURL	=>	$TicketURL,
					TicketNumber	=>	$Ticket{TicketNumber},
					Message	=> $Notification{Body},
					Created	=> $TicketDateTimeString,
					Queue	=> $Ticket{Queue},
					Service => $Ticket{Service},
					Priority => $Ticket{Priority},
					State	=>	$Ticket{State},	
					TicketID      => $TicketID, #sent for log purpose
					ReceiverName	=> $UserFullName, #sent for log purpose
		);

=cut

sub SendMessageRCAgent {
	my ( $Self, %Param ) = @_;
	
	# check for needed stuff
    for my $Needed (qw(Channel WebhookURL TicketURL TicketNumber Message Created Queue Service Priority State TicketID ReceiverName)) {
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
	#'channel'	=> $Param{Channel},
	'channel[0]'	=> '@'.$Param{Channel},  ##for direct message to user
	##'channel[1]'	=> '@maba2', ##for direct message to user 2
	'attachments[0][title]'	=> "Ticket#$Param{TicketNumber}",
	'attachments[0][text]'	=> "Create : $Param{Created}\nQueue : $Param{Queue}\nState : $Param{State}\nService : $Param{Service}\nPriority : $Param{Priority}",
	'attachments[1][title]'	=> 'View Ticket',
	'attachments[1][title_link]'	=> $Param{TicketURL},
	'attachments[1][text]'	=> 'Go To The Ticket',	  
	};
	       
	#$ua->ssl_opts(verify_hostname => 0); # be tolerant to self-signed certificates
	my $response = $ua->post( $Param{WebhookURL}, $params );
		
	#my $response = $ua->request(
	#	POST $Param{RCURL},
	#	Content_Type    => 'application/json',
	#	Content         => JSON::MaybeXS::encode_json($params)
    #   )	;
	
	my $content  = $response->decoded_content();
	my $resCode =$response->code();
	
	if ($resCode ne 200)
	{
		$Kernel::OM->Get('Kernel::System::Log')->Log(
			 Priority => 'error',
			 Message  => "RocketChat notification to $Param{ReceiverName}: $resCode $content",
		);
		return 0;
	}
	else 
	{
		return 1;
	}
}

1;

