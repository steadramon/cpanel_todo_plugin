# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the owner nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use lib '.';

# Test modules
use Test::More tests => 3 + 1;
use Test::NoWarnings;
use Test::Exception;
use Test::MockModule;
use Test::Deep;
use Test::MockTime qw( :all );

# Other modules
use File::Temp  ();
use File::Slurp ();
use JSON        ();

use_ok('Cpanel::Plugins::Cpanel::Todo::Config', 'Module loads ok');

subtest "Test config does not exists, loads defaults" => sub {

    my $dir = File::Temp->newdir();
    $Cpanel::Plugins::Cpanel::Todo::Config::FILE_PATH = $dir;

    my $config = Cpanel::Plugins::Cpanel::Todo::Config->new();
    ok $config, 'Configuration object created.';

    my $file_name = "$Cpanel::Plugins::Cpanel::Todo::Config::FILE_PATH/$Cpanel::Plugins::Cpanel::Todo::Config::FILE_NAME";
    ok !-e $file_name, "Config file does not exist";

    my $expect = build_config();
    is_deeply $config->{config}, $expect, "Configuration is loaded correctly";
    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 1, "Config is changed since the default didn't exists.";

    $config->save();
    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 0, "Config is not changed since we just saved.";

    ok -e $file_name, "Config file exists";

    is $config->param("whm.enabled"), JSON::true, "Param('whm.enabled') is true at first.";

    $config->param("whm.enabled", JSON::false);
    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 1, "Config is changed since the default didn't exists.";
    is $config->param("whm.enabled"), JSON::false, "Param('whm.enabled') is false after setting it.";

    $config->param("goofy.enabled", JSON::false);
    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 1, "Config is changed since the default didn't exists.";
    is $config->param("goofy.enabled"), JSON::false, "New Param('goofy.enabled') is false after setting it.";

    $expect = build_config("whm.enabled" => JSON::false);
    $expect->{goofy}{enabled} = JSON::false;

    is_deeply $config->{config}, $expect, "Configuration is changed correctly";
    $config->save();

    # Reload the config
    $config = Cpanel::Plugins::Cpanel::Todo::Config->new();
    ok $config, 'Configuration object created.';

    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 0, "Config is not since just loaded.";

    is_deeply $config->{config}, $expect, "Configuration is loaded correctly";
};

subtest "Test config exists" => sub {

    my $dir = File::Temp->newdir();
    $Cpanel::Plugins::Cpanel::Todo::Config::FILE_PATH = $dir;

    my $file_name = "$Cpanel::Plugins::Cpanel::Todo::Config::FILE_PATH/$Cpanel::Plugins::Cpanel::Todo::Config::FILE_NAME";
    setup_config($file_name);

    my $config = Cpanel::Plugins::Cpanel::Todo::Config->new();

    ok $config, 'Configuration object created.';

    is_deeply $config->{config}, build_config(), "Configuration is loaded correctly";

    $config->param("whm.enabled", JSON::false);
    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 1, "Config is changed since the default didn't exists.";
    is $config->param("whm.enabled"), JSON::false, "Param('whm.enabled') is false after setting it.";

    is_deeply $config->{config}, build_config("whm.enabled" => 0), "Configuration is loaded correctly";
    $config->save();

    # Reload the config
    $config = Cpanel::Plugins::Cpanel::Todo::Config->new();
    ok $config, 'Configuration object created.';

    is $config->is_loaded(), 1, "Config is loaded";
    is $config->is_changed(), 0, "Config is not since just loaded.";

    is_deeply $config->{config}, build_config("whm.enabled" => 0), "Configuration is loaded correctly";
};

sub setup_config {
    my ($file, %opts) = @_;
    my $json = build_config_json(%opts);
    File::Slurp::write_file($file, $json);
}

sub build_config_json {
    my (%opts) = @_;
    my $whm_enabled     = defined $opts{"whm.enabled"}     ? ($opts{"whm.enabled"}     ? "true" : "false") : "true";
    my $cpanel_enabled  = defined $opts{"cpanel.enabled"}  ? ($opts{"cpanel.enabled"}  ? "true" : "false") : "true";
    my $webmail_enabled = defined $opts{"webmail.enabled"} ? ($opts{"webmail.enabled"} ? "true" : "false") : "true";

    return << "DATA";
{
    "whm" : {
        "enabled" : $whm_enabled
    },
    "cpanel" : {
        "enabled" : $cpanel_enabled
    },
    "webmail" : {
        "enabled" : $webmail_enabled
    }
}
DATA
}

sub build_config {
    my (%opts) = @_;
    my $whm_enabled     = defined $opts{"whm.enabled"}     ? ($opts{"whm.enabled"}     ? JSON::true : JSON::false) : JSON::true;
    my $cpanel_enabled  = defined $opts{"cpanel.enabled"}  ? ($opts{"cpanel.enabled"}  ? JSON::true : JSON::false) : JSON::true;
    my $webmail_enabled = defined $opts{"webmail.enabled"} ? ($opts{"webmail.enabled"} ? JSON::true : JSON::false) : JSON::true;

    return {
        whm => {
            enabled => $whm_enabled,
        },
        cpanel => {
            enabled => $cpanel_enabled,
        },
        webmail => {
            enabled => $webmail_enabled,
        },
    }
}
