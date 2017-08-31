use Test::More;

BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

use Wunder::Framework::Test::Roles::Email;

my $test = Wunder::Framework::Test::Roles::Email->new;

SKIP: {
    skip "config required for mail_admin", 1, if !$test->config->{'contact'};
    ok( $test->mail_admin(
            subject => 'framework test',
            data    => 'looks good'
        )
    );
    my @deliveries = Email::Sender::Simple->default_transport->deliveries;
    is( scalar @deliveries, 1, 'email sent' );
}

done_testing();
