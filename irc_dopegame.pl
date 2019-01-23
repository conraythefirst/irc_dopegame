#!/usr/bin/perl
use strict;
use warnings;
 
use Data::Dumper;

# Subclass Bot::BasicBot to provide event-handling methods.
package DopeBot;
use base qw(Bot::BasicBot);
use Fcntl;
use GDBM_File;


my %dgstash = ();
my %dgmarket = ();
my %dgstor = ();
my %dghidden = ();
my %dgbitches = ();

tie (%dgstor, 'GDBM_File', "dgstorage", &GDBM_WRCREAT, 0640) or die "loading dgstorage: $!\n";
tie (%dgstash, 'GDBM_File', "dgstash", &GDBM_WRCREAT, 0640) or die "loading dgstash: $!\n";
tie (%dgmarket, 'GDBM_File', "dgmarket", &GDBM_WRCREAT, 0640) or die "loading dgmarket: $!\n";
tie (%dghidden, 'GDBM_File', "dghidden", &GDBM_WRCREAT, 0640) or die "loading dghidden: $!\n";

my %places = (
    #place => amount of drugs
    'park' => 6,
    'city' => 4,
    'suburbs' => 3,
    'ghetto' => 7,
    'tunnels' => 7,
    'district13' => 8,
    'village' => 6,
    'outskirts' => 4,
    'peers' => 5,
    'subway' => 5,
    );

my %commands = (
    'hustle' => [ \&_hustle ],
    'killme' => [ \&_killme ],
    'travel' => [ \&_travel ],
    'market' => [ \&_market ],
    'status' => [ \&_status ],
    'sell' => [ \&_sell ],
    'buy' => [ \&_buy ],
    'withdraw' => [ \&_withdraw ],
    'deposit' => [ \&_deposit ],
    'enter' => [ \&_enter ],
    'repay' => [ \&_repay ],
    'heal' => [ \&_heal ],
    'hide' => [ \&_hide ],
    'retrieve' => [ \&_retrieve ],
    'bitch' => [ \&_bitch ],
    'shoot' => [ \&_shoot ],
    'run' => [ \&_run ],
    'help' => [ \&_help ],
    'highscore' => [ \&_highscore ],
    
    
    );
    
my %drugs = (
    #drug [minprice, maxprice]
    "weed" => [200,800],
    "hash" => [500,1300],
    "cocain" => [15000,30000],
    "pcp" => [1000,2500],
    "xtc" => [50,300],
    "heroin" => [5500,14000],
    "meth" => [2000,6000],
    "acid" => [1000,4400],
    );

my %guns = (
    #gun [price,damage,accuracy]
    "pistol" => [1500,40,30],
    "uzi" => [4000,50,40],
    "mg" => [7500,60,60],
    "ak47" => [10000,70,70],
    "rifle" => [15000,80,75],
    "missilelauncher" => [20000,90,90],
    );

my %events = (
    "loseStuff" => [ \&_eventLoseStuff ],
    "findStuff" => [ \&_eventFindStuff ],
    "bitch4hire" => [ \&_eventBitch4hire ],
    "cops" => [ \&_eventCop ],
    "shark" => [ \&_eventLoanshark ],
    "cheapdrug" => [ \&_eventCheapDrug ],
    "expensivedrug" => [ \&_eventExpensiveDrug ],
    );

my %generalCfg = (
    "bitchStorage" => 10,
    "bitchPrice" => 1000,
    "playerHealth" => 100,
    "playerMoney" => 2000,
    "playerDept" => 2000,
    "playerBag" => 100,
    "bankInterest" => 1.005,
    "debtInterest" => 1.1,
    
    );
 
sub said {
    my $self      = shift;
    my $arguments = shift;    
    
   #parse commands
    if ($arguments->{body} =~ m/^!dg\s*(\w+)\s*?(.*)?/) {
        my $cmd = $1;
        my $args = $2;
       
        return if (!$dgstor{$arguments->{who}} and $cmd !~ m!^h(ustle|elp)!);
       
        if ( defined $commands{$cmd} ) {
            my $ret = $commands{$cmd}->[0]($arguments->{who}, $args);
            
            #post results
            if ( defined $ret ) {
                foreach my $return (split("\n", $ret)) {
                    $self->say(
                        channel => $arguments->{channel},
                        body    => $return,
                        who    => $arguments->{who},
                        address    => $arguments->{who},
                    );
                }
            }
        }
          
    }
    
    return;
     
}


sub _hustle {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    return "You are already playing.\n" if ($dgstor{$who});
    
    #init game
    $dgstor{$who} = $who;
    $dgstor{$who."_hp"} = $generalCfg{"playerHealth"};
    $dgstor{$who."_money"} = $generalCfg{"playerMoney"};
    $dgstor{$who."_debt"} = $generalCfg{"playerDebt"};
    $dgstor{$who."_place"} = "loansharks place";
    $dgstor{$who."_bag"} = $generalCfg{"playerBag"};
    $dgstor{$who."_age"} = 0;
    $dgstor{$who."_bank"} = 0;
    $dgstor{$who."_bitches"} = 0;
    $dgstor{$who."_hiddenmoney"} = 0;
    $dgstor{$who."_hideout"} = 0;
    $dgstor{$who."_evasion"} = 0;
    $dgstor{$who."_armor"} = 0;
    $dgstor{$who."_wanted"} = 0; #wanted level
    
    $dgstor{$who."_doctor"} = 1;
    $dgstor{$who."_clerk"} = 1;
    $dgstor{$who."_barkeeper"} = 1;
    $dgstor{$who."_gunshop"} = 1;
    $dgstor{$who."_loanshark"} = 1;
    $dgstor{$who."_bitchprice"} = $generalCfg{"bitchPrice"};
    
    $return .= "'I expect that \$".$generalCfg{"playerMoney"}." back within 20 days max with 10% interest a day or else.. motherfucker. better hustle good!'\n";    
    $return .= "You recieved \$".$generalCfg{"playerMoney"}." from a loanshark. You'll need to repay it within 20 days\n";    
    $return .= "You can return here by traveling to the ghetto and using '!dg shark'\n";    
    return $return;
}


sub _killme {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    #game over
    
    if ($dgstor{$who."_hp"} <= 0) {
        $return .= "You got killed by the ".$dgstor{$who."_opponent"}."!\n";
    }
    else {
        $return .= "Lightning hit you while taking a dump!\n";
    }
    
    $return .= "You died after hustling for ".$dgstor{$who.'_age'}."days!\n";    
    $return .= "You left behind \$".$dgstor{$who.'_money'}."\n";
    
    #tidy up
    delete($dgstor{$who});
    foreach my $stash (keys %dgstash) {
        if ($stash =~ m!^$who\_!) {
            delete($dgstash{$stash});
        }
    }
    foreach my $stor (keys %dgstor) {
        if ($stor =~ m!^$who\_!) {
            delete($dgstor{$stor});
        }
    }
    foreach my $market (keys %dgmarket) {
        if ($market =~ m!^$who\_(.*)!) {
            delete($dgmarket{$market});
        }
    }
    
    return $return;
}


sub _travel {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my ($place) = $args =~ m!(\w+)!;
    
    return "Invalid input!\n" if (!$place);
    return "You already are in the ".$place."!\n" if ($dgstor{$who."_place"} eq $place);
    
    if ($dgstor{$who."_event"} and $dgstor{$who."_event"} =~ m!fight$!) {
        return "You are in the middle of a situation here..\n";
    }
    
    #setting bitchprice to default in case eventBitch4Hire was called
    if ($dgstor{$who."_event"} and $dgstor{$who."_event"} eq "bitch4hire") {
        $dgstor{$who."_bitchprice"} = $generalCfg{"bitchPrice"};
        delete($dgstor{$who."_event"});
    }
    
    #delete previous entries
    foreach my $tmp (keys %dgmarket) {
        delete($dgmarket{$tmp}) if ($tmp =~ m!^$who!);
    }
    
    if ($places{$place}) {
        $dgstor{$who.'_age'}++;
        $dgstor{$who.'_bank'} = &__round( $dgstor{$who."_bank"} * $generalCfg{"bankInterest"});
        $dgstor{$who.'_debt'} = &__round($dgstor{$who.'_debt'} * $generalCfg{"debtInterest"}) if ($dgstor{$who."_loanshark"} eq 1);
        $dgstor{$who.'_place'} = $place;
        $return .= "You arrived at the ".$place." on day ".$dgstor{$who.'_age'}."\n";
        
        my @lastrand = ();
        foreach (1..$places{$place}) {
            my $rand = int(rand(scalar(keys %drugs)));
            
            #make sure same drug isn't used twice
            redo if ( grep { $rand eq $_ } @lastrand);
            push(@lastrand, $rand);
            
            #setting drug prices for specified place
            my $localdrug = (keys %drugs)[$rand];
            $dgmarket{$who."_".$localdrug} = int(rand(@{$drugs{$localdrug}}[1] - @{$drugs{$localdrug}}[0]) + @{$drugs{$localdrug}}[0]);
            
            $return .= $localdrug." goes for \$".$dgmarket{$who."_".$localdrug}."\n";
        }
        
        #check if there were bitches at work
        if ($dgbitches{$who."_".$dgstor{$who.'_age'}}) {
            my $earnings = 0;
            foreach (1..$dgbitches{$who."_".$dgstor{$who.'_age'}}) {
                #bitches earn $30-$100 a day
                $earnings += int(rand(70) + 30) foreach (1..5);
            }
            $dgstor{$who.'_bitches'} += $dgbitches{$who."_".$dgstor{$who.'_age'}};
            $dgstor{$who.'_money'} += $earnings;
            
            $return .= $dgbitches{$who."_".$dgstor{$who.'_age'}}." bitches have returned to you\n";
            $return .= "Your bitches earned you \$".$earnings."!\n";
            
            delete($dgbitches{$who."_".$dgstor{$who.'_age'}});
        }
        
        $return .= &_triggerEvent($who);
    }
    return $return;    
}


sub _market {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    $return .= "Current market for ".$dgstor{$who.'_place'}."\n";
    
    foreach my $market (keys %dgmarket) {
        if ($market =~ m!^$who\_(\w+)!) {
            my $drug = $1;
            $return .= $drug." goes for \$".$dgmarket{$market}."\n" if ($dgmarket{$market});
        }
    }
    return $return;    
}


sub _status {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    $return .= "You've been hustling for ".$dgstor{$who.'_age'}." days\n";
    $return .= "You have \$".$dgstor{$who.'_bank'}." in the bank\n";
    $return .= "You got \$".$dgstor{$who.'_money'}." in your pocket\n";
    $return .= "You're carrying a ".$dgstor{$who.'_gun'}."\n" if ($dgstor{$who."_gun"});
    $return .= "You owe \$".$dgstor{$who.'_debt'}." to the loanshark\n" if ($dgstor{$who."_loanshark"} and $dgstor{$who."_debt"} > 0);
    $return .= "You are in the ".$dgstor{$who.'_place'}."\n";
    $return .= "You are surrounded by ".$dgstor{$who.'_bitches'}." bitches\n" if ($dgstor{$who.'_bitches'} > 0);
    $return .= "You're injured! " if ($dgstor{$who.'_hp'} < $generalCfg{"playerHealth"});
    $return .= "Health: ".$dgstor{$who.'_hp'}."\%\n";
    $return .= "Storage: ".&_checkBag($who,0)."\n";
        
    #personal stash
    foreach my $entry (keys %dgstash) {
        if ($entry =~ m!$who\_(\w+)!) {
            my $drug = $1;
            $return .= "You have ".$dgstash{$who."_".$drug}." ".$drug." on you\n" if ($dgstash{$who."_".$drug} and $dgstash{$who."_".$drug} > 0);
        }
    }
    
    
    return $return;
}


sub _sell {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my $drug;
    my $amount;
    
    if ($args =~ m!(\w+)\s*(\d+)!) {
        $drug = $1;
        $amount = $2;
    }
    
    return "Invalid input\n" if (!$drug or !$amount or $amount < 0);
    return $drug." not traded here\n" if (!$drugs{$drug} or !$dgmarket{$who."_".$drug});
    return "You don't have any ".$drug."\n" if (!$dgstash{$who."_".$drug});
    return "You don't have so much ".$drug."\n" if ($dgstash{$who."_".$drug} < $amount);
    
    my $profit = $dgmarket{$who."_".$drug} * $amount;
    $dgstor{$who."_money"} += $profit;
    $dgstash{$who."_".$drug} -= $amount;
    delete($dgstash{$who."_".$drug}) if ($dgstash{$who."_".$drug} <= 0);
    
    return "You sold ".$amount." ".$drug." for \$".$profit;    
}


sub _buy {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my $item;
    my $amount;

    if ($args =~ m!^\s*?(\w+)\s*(\d*)!) {
        $item = $1;
        $amount = $2;
    }
    
    if ($dgstor{$who."_encounter"} and $dgstor{$who."_encounter"} eq "gunshop") {
        ($item) = $args =~ m!(\w+)!;
        $amount = 1 if ($guns{$item});
    }
    
    return "Invalid input ".$item." - ".$amount."\n" if (!$item or !$amount or $amount < 0);
    return $item." is not sold here\n" if (!$dgmarket{$who."_".$item}); # or !$drugs{$item});
    
    my $price = $dgmarket{$who."_".$item} * $amount;
    return "You don't have enough money to buy ".$amount." ".$item."\n" if ($price > $dgstor{$who."_money"});
    return "You don't have enough storage space left\n" if (! &_checkBag($who,$amount));
    
    $dgstor{$who."_money"} -= $price;
    $dgstash{$who."_".$item} += $amount if ($drugs{$item});
    $dgstor{$who."_gun"} = $item if ($guns{$item}); #bought a gun
        
    return "You bought ".$amount." ".$item." for \$".$price;
    
}


sub _enter {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my $place;
    
    if ($args =~ m!(\w+)!) {
        $place = $1
    }
    #bank
    if ($place eq "bank") {
        return "You can only visit the bank in the city!\n" if ($dgstor{$who."_place"} ne "city");
    
        if ($dgstor{$who."_clerk"} eq 1) {
            $dgstor{$who."_encounter"} = "clerk";
            $dgstor{$who."_opponent"} = "Clerk";
            $dgstor{$who."_opponentHP"} = 50;
            $dgstor{$who."_opponentPower"} = 10;
            $return .= "Welcome to the bank. You can withdraw and deposit your money here!\n";
            $return .= "You currently have \$".$dgstor{$who."_bank"}." stored here.\n";
        }
        else {
            $return .= "The bank clerk is dead. You can't access your funds anymore!";
        }
    }
    #loanshark    
    elsif ($place eq "shark" or $place eq "loanshark") {
        return "You can only visit the loanshark in the ghetto!\n" if ($dgstor{$who."_place"} ne "ghetto");
    
        if ($dgstor{$who."_loanshark"} eq 1) {
            $dgstor{$who."_encounter"} = "loanshark";
            $dgstor{$who."_opponent"} = "Loanshark";
            $dgstor{$who."_opponentHP"} = 200;
            $dgstor{$who."_opponentPower"} = 50;
            
            if ($dgstor{$who."_debt"} > 0) {
                if ($dgstor{$who."_age"} < 20) {
                    $return .= "You again.. I hope for you, you got my money!\n";
                }
                elsif ($dgstor{$who."_age"} >= 20) {
                    $return .= "You've got some nerves to show up here...\n";
                    $return .= "I'll take my money and your life you fool!!\n";
                    $return .= &_takeDamage($who, $dgstor{$who."_opponentPower"});
                }
            }
        }
        else {
            return "The loanshark is dead. You can't go to his place anymore!\n";
        }
    }
    #bar
    elsif ($place eq "bar") {
        return "You can only visit the bar in the village!\n" if ($dgstor{$who."_place"} ne "village");
    
        if ($dgstor{$who."_barkeeper"} eq 1) {
            $dgstor{$who."_encounter"} = "barkeeper";
            $dgstor{$who."_opponent"} = "Barkeeper";
            $dgstor{$who."_opponentHP"} = 80;
            $dgstor{$who."_opponentPower"} = 30;
            $dgstor{$who."_bitchprice"} = 1000;
            
            $return .= "Welcome to the bar. Interessted in some assistance?\n";
            $return .= "You can hire a bitch for \$1000\n";
        }
        else {
            $return .= "The barkeeper is dead. You can't hire any bitches here anymore!\n";
        }
    }
    #gunshop
    elsif ($place eq "gunshop") {
        return "You can only visit the gunshop in the outskirts!\n" if ($dgstor{$who."_place"} ne "outskirts");
    
        if ($dgstor{$who.'_gunshop'} eq 1) {
            $dgstor{$who."_encounter"} = "gunshop";
            $dgstor{$who."_opponent"} = "Gunshop owner";
            $dgstor{$who."_opponentHP"} = 100;
            $dgstor{$who."_opponentPower"} = 35;
            
            $return .= "Welcome to the gunshop. Interested in some guns?\n";
            foreach my $gun (keys %guns) {
                $dgmarket{$who."_".$gun} = @{$guns{$gun}}[0];
                $return .= "A ".$gun." costs \$".@{$guns{$gun}}[0]."\n";
            }
        }
        else {
            $return .= "The gunshop owner is dead. You can't buy any guns here anymore!\n";
        }
    }
    #hospital
    elsif ($place eq "hospital") {
        return "You can only visit the hospital in the distric13!\n" if ($dgstor{$who."_place"} ne "district13");
    
        if ($dgstor{$who.'_doctor'} eq 1) {
            $dgstor{$who."_encounter"} = "doctor";
            $dgstor{$who."_opponent"} = "Doctor";
            $dgstor{$who."_opponentHP"} = 40;
            $dgstor{$who."_opponentPower"} = 20;
            
            $return .= "Welcome to the hospital. You can get healed here for \$500\n";
        }
        else {
            $return .= "The doctor is dead. You can't get healed here anymore!\n";
        }
        
    }
    #home
    elsif ($place eq "home") {
        if ($dgstor{$who."_place"} eq "suburbs") {
            $return .= "You've returned to you crappy appartement. You can hide some money here..\n";
            $return .= "You've currently hidden \$".$dgstor{$who."_hiddenmoney"}." under your bed\n" if ($dgstor{$who."_hiddenmoney"} > 0);
        }
    }
    #hideout
    #elsif ($place eq "hideout") {
        #if ($dgstor{$who."_place"} eq "district13" and $dgstor{$who."_hideout"} eq 1) {
            #$return .= "You've entered your hideout. You can hide your stash here..\n";
            #foreach my $entry (keys %dghidden) {
                #if ($entry =~ m!^$who\_(.*)!) {
                    #my $drug = $1;
                    #$return .= "You've currently hidden ".$dghidden{$who."_".$drug}." ".$drug." here\n";        
                #}
            #}
        #}
    #}
    else {
        $return .= "Location unknown!\n";
    }
    
    
    return $return;
    
}


sub _withdraw {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my ($amount) = $args =~ m!(\d+)!;
    
    return "Invalid input ".$amount."\n" if (!$amount);
    return "You can only withdraw your money in the bank!\n" if ($dgstor{$who."_place"} ne "city");
    
    if ($dgstor{$who."_clerk"} eq 1) {
        return "You don't have that much money!\n" if ($dgstor{$who."_bank"} < $amount);
        $dgstor{$who."_money"} += $amount;
        $dgstor{$who."_bank"} -= $amount;
        $return .= "You've withdrawn \$".$amount." from your account.\n";
        $return .= "Your new balance is \$".$dgstor{$who."_bank"}."\n";
    
    }
    else {
        $return .= "The bank clerk is dead. You can't access your funds anymore!";
    }
    
    return $return;
}



sub _deposit {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my ($amount) = $args =~ m!(\d+)!;
    
    return "Invalid input $amount\n" if (!$amount);
    return "You can only deposit your money in the bank!\n" if ($dgstor{$who."_place"} ne "city");
    
    if ($dgstor{$who."_clerk"} eq 1) {
        return "You don't have that much money on you!\n" if ($dgstor{$who."_money"} < $amount);
        $dgstor{$who."_money"} -= $amount;
        $dgstor{$who."_bank"} += $amount;
        $return .= "You've deposited \$".$amount." in your account.\n";
        $return .= "Your new balance is \$".$dgstor{$who."_bank"}."\n";
    
    }
    else {
        $return .= "The bank clerk is dead. You can't access your funds anymore!";
    }
    
    return $return;
}


sub _repay {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    return "You can only repay your debt at the loansharks place!\n" if ($dgstor{$who."_place"} ne "ghetto");
    
    if ($dgstor{$who."_loanshark"} eq 1) {
        return "You don't have enough money to repay your debt!\n" if ($dgstor{$who."_money"} <= $dgstor{$who."_debt"});
        $dgstor{$who."_money"} -= $dgstor{$who."_debt"};
        $dgstor{$who."_debt"} = 0;
        $return .= "You did repay you debt after all.. Now go out of my sight!\n";
    }
    else {
        $return .= "The loanshark is dead. He already got his payback!\n";
    }
    
    return $return;
}


sub _bitch {
    my $who = shift;
    my $args = shift;
    
    my $command = "";
    my $amount;
    
    if ($args =~ m!(\w+)\s*(\d+)?!) {
        $command = $1;
        $amount = $2;
    }
    $amount = 1 if (!$amount);
    
    my $return = "";
    
    return "You have no bitches to boss around!\n" if ($dgstor{$who."_bitches"} <= 0);
    
    if ($command eq "hire") {
        return "You can only hire a bitch at the bar in the village!\n" if ($dgstor{$who."_place"} ne "village" and $dgstor{$who."_event"} ne "bitch4hire");
        
        if ($dgstor{$who."_event"} eq "bitch4hire" or $dgstor{$who."_encounter"} eq "barkeeper") {
            $amount = 1 if ($dgstor{$who."_event"} eq "bitch4hire");
            my $price = $dgstor{$who."_bitchprice"} * $amount;
            if ($dgstor{$who."_money"} >= $price) {
                $dgstor{$who."_money"} -= $price;
                $dgstor{$who."_bitches"} += $amount;
                $return .= "You hired ".$amount." bitches for \$".$price."\n";
                
                #end event bitch4hire if it was in effect
                if ($dgstor{$who."_event"} and $dgstor{$who."_event"} eq "bitch4hire") {
                    $dgstor{$who."_bitchprice"} = $generalCfg{"bitchPrice"};
                    delete($dgstor{$who."_event"});
                }
                
            }
            else {
                $return .= "You don't have enough money to hire a bitch!\n";
            }
        }
        else {
                $return .= "There are no bitches to hire!\n";
        }
    }
    elsif ($command eq "work") {
        my $bitchreturn = $dgstor{$who."_age"} + 5;
        $dgbitches{$who."_".$bitchreturn} += $amount;
        $dgstor{$who."_bitches"} -= $amount;
        $return .= "You've send ".$amount." bitches to work for 5 days\n";
    }
    elsif ($command eq "fire") {
        $dgstor{$who."_bitches"} -= $amount;
        $return .= "You've fired ".$amount." bitch!\n";
    }
    else {
        $return .= "Your order was incomprehensible!\n";
    }
    
    return $return;
    
}


sub _heal {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    return "You can only get healed at the shady hospital in distric13!\n" if ($dgstor{$who."_encounter"} and $dgstor{$who."_encounter"} ne "doctor");
    
    if ($dgstor{$who."_doctor"} eq 1) {
        $return .= "You don't have enough money for treatment!\n" if ($dgstor{$who."_money"} < 500);
        $dgstor{$who."_money"} -= 500;
        $dgstor{$who."_hp"} = 100;
        $return .= "You are all good now! Thanks for the business\n";
    }
    else {
        $return .= "The doctor is dead. You can't get healed here anymore!\n";
    }
    
    return $return;
}


sub _retrieve {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my $item;
    my $amount;
    
    if ($args =~ m!(\w+)\s*(\d+)!) {
        $item = $1;
        $amount = $2;
    }
    else {
        return "Invalid input!\n";
    }
    
    return "How much??\n" if (!$amount);
    
    if ($item eq "money" and $dgstor{$who."_place"} eq "suburbs") {
        if ($amount <= $dgstor{$who."_hiddenmoney"}) {
            $dgstor{$who."_money"} += $amount;
            $dgstor{$who."_hiddenmoney"} -= $amount;
            $return .= "You retrieved \$".$amount." from under your bed\n";
        }
        else {
            $return .= "You don't have that much money hidden!\n";
        }
    }
    elsif ($drugs{$item} and $dgstash{$who."_".$item} and $dgstor{$who."_place"} eq "hideout") {
        if ($amount <= $dghidden{$who."_".$item}) {
            return "You don't have enough storage space left\n" if (! &_checkBag($who,$amount));
            
            $dghidden{$who."_".$item} -= $amount;
            delete($dghidden{$who."_".$item}) if ($dghidden{$who."_".$item} eq 0);
            $dgstash{$who."_".$item} += $amount;
            $return .= "You retrieved ".$amount." of ".$item." from a safe place\n";
        }
        else {
            $return .= "You don't have that much ".$item." hidden here!\n";
        }
    }
    else {
        $return .= "You can't do that here!\n";
    }        
    
    return $return;
    
}


sub _hide {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    my $item;
    my $amount;
    
    if ($args =~ m!(\w+)\s*(\d+)!) {
        $item = $1;
        $amount = $2;
    }
    else {
        return "Invalid input!\n";
    }
    
    return "How much??\n" if (!$amount);
    
    if ($item eq "money" and $dgstor{$who."_place"} eq "suburbs") {
        if ($amount <= $dgstor{$who."_money"}) {
            $dgstor{$who."_hiddenmoney"} += $amount;
            $dgstor{$who."_money"} -= $amount;
            $return .= "You hid \$".$amount." under your bed\n";
        }
        else {
            $return .= "You don't have that much money on you!\n";
        }
    }
    elsif ($drugs{$item} and $dgstash{$who."_".$item} and $dgstor{$who."_place"} eq "hideout") {
        if ($amount <= $dgstash{$who."_".$item}) {
            $dghidden{$who."_".$item} += $amount;
            $dgstash{$who."_".$item} -= $amount;
            $return .= "You hid ".$amount." of ".$item." in a safe place\n";
        }
        else {
            $return .= "You don't have that much ".$item." on you!\n";
        }
    }
    else {
        $return .= "You can't do that here!\n";
    }        
    
    return $return;
    
}


sub _run {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    if ($dgstor{$who."_event"}) {
        my $chance = int(rand(100)+1) + $dgstor{$who."_evasion"};
        
        if ($dgstor{$who."_event"} eq "sharkfight" or $dgstor{$who."_event"} eq "copfight") {
            if ($chance > 50) {
                $return .= "You got away\n";
                delete($dgstor{$who."_event"});
            }
            else {
                $return .= "You tried hard but you didn't manage to flee\n";
                $return .= &_takeDamage($who, $dgstor{$who."_opponentPower"});
            }
        }
        else {
            $return .= "No point in running anywhere\n";
        }
        
    }
    else {
            $return .= "No point in running anywhere\n";
    }
    
    return $return;
}


sub _shoot {
    my $who = shift;
    my $args = shift;

    my $return = "";
    
    if ($dgstor{$who."_encounter"}) {
        if ($dgstor{$who."_gun"}) {
            my $chance = int(rand(100)+1);
            if ($chance < 20) {
                $return .= "You missed!\n";
                $return .= &_takeDamage($who,$dgstor{$who."_opponentPower"});
                return $return;
            }
            elsif ($chance > 90) {
                
                $return .= "You landed a lucky headshot!\n";
                $return .= &_opponentDead($who);
                
                return $return;
            }
            else {
                my $gunAccuracy = @{$guns{$dgstor{$who."_gun"}}}[2];
                my $gunDamage = @{$guns{$dgstor{$who."_gun"}}}[1];
                my $damage = int(rand(100 - $gunAccuracy) + $gunAccuracy) / 100 * $gunDamage;
                
                $return .= "You dealt ".$damage." damage..\n";
                $dgstor{$who."_opponentHP"} -= $damage;
                
                if ($dgstor{$who."_opponentHP"} <= 0) {
                    $return .= "You hit! The ".$dgstor{$who."_opponent"}." falls on the floor!\n";
                    $return .= &_opponentDead($who);

                    return $return;
                }
                else {
                    $return .= "You've landed a hit!\n";
                    $return .= "The ".$dgstor{$who."_opponent"}." got ".$dgstor{$who."_opponentHP"}."HP left.\n";
                    $return .= &_takeDamage($who,$dgstor{$who."_opponentPower"});
                    
                    return $return;
                }
                
            }
        }
        else {
            $return .= "You don't have a gun!\n";
        }
    }
    else {
            $return .= "No point in shooting around\n";
    }
    
    return $return;
}


sub _opponentDead {
    my $who = shift;
    
    my $return .= "The ".$dgstor{$who."_opponent"}." is dead!\n";
    
    my $loot = int(rand(1300)+100);
    $return .= "You looted \$".$loot."!\n";
    
    $dgstor{$who."_".$dgstor{$who."_encounter"}} = 0;    
    $dgstor{$who."_money"} += $loot;                
    $dgstor{$who."_wanted"}++;                
    delete($dgstor{$who."_encounter"});
    delete($dgstor{$who."_event"});
    delete($dgstor{$who."_opponent"});
    delete($dgstor{$who."_opponentHP"});
    
    return $return;
}


sub _takeDamage {
    my $who = shift;
    my $power = shift;
    
    my $return = "The ".$dgstor{$who."_opponent"}." attacks you!\n";
    
    my $chance = int(rand(100)+1) + $dgstor{$who."_evasion"};
    if ($chance > 60) {
        $return .= "You managed to dodge that!\n";
    }
    elsif ($dgstor{$who."_bitches"} > 0  and int(rand(100) + 1 + $dgstor{$who."_bitches"}) <= 75) {
        $return .= "One of you bitches shielded you and died";
        $dgstor{$who."_bitches"}--;        
    }
    else {
        my $damage = int(rand($power)+1) - $dgstor{$who."_armor"};
        $dgstor{$who."_hp"} -= $damage;
        $return .= "You got hit!";
        
        if ($dgstor{$who."_hp"} <= 0) {
            &_killme($who,0);
        }
    }
    
    return $return;
    
}


sub _triggerEvent {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    if (int(rand(5)+1) eq 4) {
        #start event
        my $event = (keys %events)[int(rand(scalar(keys %events)))];
        $return .= $events{$event}->[0]($who);
    }
    
    return $return;
}


sub _eventCop {
    my $who = shift;
    
    my $return = "";
    
    if (int(rand(100) + $dgstor{$who."_wanted"}) > 50) {
        $dgstor{$who."_event"} = "copfight";
        $dgstor{$who."_encounter"} = "cop";
        $dgstor{$who."_opponent"} = "Cop";
        $dgstor{$who."_opponentHP"} = 150;
        $dgstor{$who."_opponentPower"} = 60;
        $return .= "A cop stops you and begins to question you!\n";
        $return .= "You can try to run away or take your chances and start a fight...\n";
    }
    else {
        $return .= "A cop looks at you very suspicious, but doesn't bother you any further.\n";
    }
        
    return $return;
}



sub _eventLoanshark {
    my $who = shift;
    
    my $return = "";
    
    if ($dgstor{$who."_loanshark"} eq 1) {
        if ($dgstor{$who."_age"} > $dgstor{$who."_deadline"} and int(rand(100) + 1) > 65) {
            $dgstor{$who."_event"} = "sharkfight";
            $dgstor{$who."_encounter"} = "loanshark";
            $dgstor{$who."_opponent"} = "Loanshark";
            $dgstor{$who."_opponentHP"} = 200;
            $dgstor{$who."_opponentPower"} = 50;
            $return .= "The loanshark appears behind you.\n";
            $return .= "Loanshark: There you are you scum. Noone steals from me!\n";
            $return .= "You can try to run away or take your chances and start a fight...\n";
            $return .= &_takeDamage($who, $dgstor{$who."_opponentPower"});
        }
        else {
            $return .= "You spotted the loanshark but managed to dodge him..\n";
        }
    }

    return $return;
}


sub _eventFindStuff {
    my $who = shift;
    
    my $return = "";
    
    if (int(rand(100)) > 50) {
        my $amount = int(rand(500) + 10);
        $return .= "You found some money lying on the street!\n";
        $return .= "You got \$".$amount."\n";
        $dgstor{$who."_money"} += $amount;
    }
    else {
        #get random drug
        my $drug = (keys %drugs)[int(rand(scalar((keys %drugs))))];
        my $amount = int(rand(5) + 1);
        $return .= "On your stroll, you found ".$amount." ".$drug." in a dirty bag!\n";
        
        if ($dgstash{$who."_".$drug}) {
            return "You don't have enough storage space left\n" if (! &_checkBag($who,$amount));
            $dgstash{$who."_".$drug} += $amount;
        }
        else {
            $dgstash{$who."_".$drug} = $amount;
        }
    }
    
    return $return;
    
}


sub _eventLoseStuff {
    my $who = shift;
    
    my $return = "";
    
    if (int(rand(100)) > 50) {
        my $amount = int(rand($dgstor{$who."_money"} - 1) + 1);
        $dgstor{$who."_money"} -= $amount;
        $return .= "Some shady looking dudes approached you in a dark alleyway.\n";
        $return .= "You lost \$".$amount." while running away\n";

    }
    else {
        #get random drug from stash
        my @stash = ();
        foreach my $entry (keys %dgstash) {
            if ($entry =~ m!$who\_(\w+)!) {
                push(@stash, $1);
            }
        }
        
        my $drug = $stash[int(rand($#stash))];
        my $amount = int(rand($dgstash{$who."_".$drug} - 1) + 1);
        $dgstash{$who."_".$drug} -= $amount;
        $return .= "Some shady looking dudes approached you in a dark alleyway.\n";
        $return .= "You lost ".$amount." ".$drug." during your escape!\n";
        
    }
    
    return $return;
    
}


sub _eventCheapDrug {
    my $who = shift;
    
    my $return = "";
    my @available = ();
    
    foreach my $entry (keys %drugs) {
        if (!$dgmarket{$who."_".$entry}) {
            push(@available, $entry)
        }
    }
    
    my $drug = $available[int(rand($#available))];
    
    return if (!$drugs{$drug});
    
    my $price = int(rand(@{$drugs{$drug}}[0]) + 1);
    $return .= "The market is flooded with cheap ".$drug."!\n";
    $return .= $drug." goes for \$".$price."\n";
    $dgmarket{$who."_".$drug} = $price;
        
    return $return;
    
}



sub _eventExpensiveDrug {
    my $who = shift;
    
    my $return = "";
    my @available = ();

    foreach my $entry (keys %drugs) {
        if (!$dgmarket{$who."_".$entry}) {
            push(@available, $entry)
        }
    }
    
    my $drug = $available[int(rand($#available))];
    
    return if (!$drugs{$drug});
    
    my $price = int(rand(@{$drugs{$drug}}[1]) + 1) + @{$drugs{$drug}}[1];
    $return .= "The police raided a large ".$drug." operation! Prices are crazy...\n";
    $return .= $drug." goes for \$".$price."\n";
    $dgmarket{$who."_".$drug} = $price;
        
    return $return;
    
}


sub _eventBitch4hire {
    my $who = shift;
    
    my $return = "";
    
    #reset bitchprice
    my $price = $generalCfg{"bitchPrice"} / 2;
    $dgstor{$who."_bitchprice"} = int(rand($price) + $price);
    $dgstor{$who."_event"} = "bitch4hire";
    
    $return .= "A bitch walks up to you and asks for a job!";
    $return .= "You can hire this one for \$".$dgstor{$who."_bitchprice"};
    
    return $return;
}


sub _help {
    my $who = shift;
    my $args = shift;
    
    my $return = "";
    
    $return .= "available commands:\n";
    $return .= "!dg hustle                     -> start the game\n";
    $return .= "!dg buy [item] [amount]             -> buy specified amount of item\n";
    $return .= "!dg sell [item] [amount]             -> sell specified amount of item\n";
    $return .= "!dg travel [place]                 -> travel to the specified place (it takes all day)\n";    
    $return .= "!dg shoot                     -> fire your gun (will only work in an encounter)\n";
    $return .= "!dg run                         -> try to escape (will only work in an encounter)\n";
    $return .= "!dg enter [place]                 -> enter a building like the bar or gunshop etc.\n";
    $return .= "!dg withdraw                     -> withdraw money from the bank\n";
    $return .= "!dg deposit                     -> deposit money in the bank (interestrate: 0.5\%)\n";
    $return .= "!dg repay                     -> repay your debt to the loanshark\n";
    $return .= "!dg heal                     -> get treatment in the hospital\n";
    $return .= "!dg status                     -> get your current status\n";
    $return .= "!dg market                     -> get the current marketoffers in your place\n";
    $return .= "!dg hide [item] [amount]             -> hide specified amount of item in your appartement or hideout\n";
    $return .= "!dg retrieve [item] [amount]             -> retrieve specified amount of item in your appartement or hideout\n";
    $return .= "!dg bitch [hire,fire,work]             -> hire, fire or send a bitch to work for 5 days\n";
    $return .= "!dg killme                     -> end the game\n";
    $return .= "places: ".join(',', (keys %places))."\n";
    $return .= "buildings to enter: bar(village), hospital(district13), bank(city), gunshop(outskirts), shark(ghetto), home(suburbs)\n";
    
    return $return;
}


sub _highscore {
    my $who = shift;
    my $args = shift;

    my $return = "HIGHSCORE:\n";
    
    my @richest = ("nobody", 0);
    my @oldest = ("nobody", 0);
    
    foreach my $entry (keys %dgstor) {
        if ($entry =~ m!(.*)_age$!) {
            my $player = $1;
            next if (!$dgstor{$player});
            
            if ($oldest[1] < $dgstor{$entry}) {
                $oldest[0] = $player;
                $oldest[1] = $dgstor{$entry};
            }
        }
        if ($entry =~ m!(.*)_money$!) {
			my $player = $1;
            my $funds = $dgstor{$player."_money"} + $dgstor{$player."_bank"};
			next if (!$dgstor{$player});
			
			if ($richest[1] < $funds) {
					$richest[0] = $player;
					$richest[1] = $funds;
			}
        }
    }
    $return .= "The oldest hustler is '".$oldest[0]."' with ".$oldest[1]." days of hustling\n";
    $return .= "The richest hustler is '".$richest[0]."' with \$".$richest[1]." worth of funds\n";

    return $return;
}


sub _checkBag {
    my $who = shift;
    my $amount = shift;

    my $max = $dgstor{$who."_bitches"} * $generalCfg{"bitchStorage"} + $dgstor{$who."_bag"};
    my $used = 0;
    foreach my $entry (keys %dgstash) {
        if ($entry =~ m!^$who\_!) {
            $used += $dgstash{$entry};
        }
    }
    my $result = $used + $amount;
    if ($result <= $max) {
        return $result."/".$max;
    }
    else {
        return;
    }
}


sub __debug {
    open(FH,'>>','/tmp/dopebot');
    print FH Data::Dumper->Dumper(shift)."\n";
    close FH; 
}


sub __round {
    my $i = shift;
    if ($i < (int($i) + 0.5)) {
        $i = int($i);
    }
    else {
        $i = int($i) + 1;
    }
    return $i;
}


END { 
    untie %dgstor;
    untie %dgstash;
    untie %dgmarket;
    untie %dghidden;
    untie %dgbitches;
}


# Create an object of your Bot::BasicBot subclass and call its run method.
package main;
 
my $bot = DopeBot->new(
    server      => 'irc.example.com',
    #ssl         => 1,
    port        => '6667',
    channels    => ['#channel'],
    nick        => 'Dopebot',
    name        => 'Dope Bot',
    #disable POE flood protection
    flood    => 1,
);

$bot->run();



