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


1;
