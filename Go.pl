#!/usr/bin/env perl


{
# [2025-08-28]
#   We steal from the `221227_PerlLib_02h` Project...
package Util;
use Exporter qw (import);
our @EXPORT = qw
(
	printf_2
	Die Croak Warn
	Azzert
	IsHashOrObject
	GetOrSetObjectProperty
);

use strict; use warnings;

sub printf_2
{
	{ use IO::Handle; STDOUT->flush (); }
	return printf STDERR (@_);
}

sub Die
{
	{ use IO::Handle; STDOUT->flush (); }
	die (@_);
}

sub Croak
{
	{ use IO::Handle; STDOUT->flush (); }
	{ use Carp; croak (@_); }
}

sub Warn
{
	{ use IO::Handle; STDOUT->flush (); }
	warn (@_);
}

sub Azzert
{
	my $bCondition = shift;
	
	if (! $bCondition)
	{
		my $sMessage = shift;
		{
			if (! defined ($sMessage))
			{
				$sMessage = 'No message.';
			}
		}
		
		&Croak ("Error: Azzertion has failed. ${sMessage}");
	}
	
	return $bCondition;
}

sub IsHashOrObject
{
	my $self = @_ ? shift : &Azzert ();
	eval { sub f { my $self = shift; return scalar keys %$self; } &f ($self); };
	return ! length ($@);
}

sub GetOrSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $value = shift;
		$self->{$sProperty} = $value;
		return $self;
	}
	else
	{
		return $self->{$sProperty};
	}
}

1;
}


{
# [2025-08-29]
#   We steal from the `221227_PerlLib_02h` Project...
package DestroyGuard;
Util->import ();
use strict; use warnings;

sub CreateObject
{
	my $sClassName = @_ ? shift : &Azzert ();
	
	my $self =
	{
		'rfnOnDestroy' => shift
	};
	
	return bless ($self, $sClassName);
}

sub OnDestroy
{
	return &GetOrSetObjectProperty ('rfnOnDestroy', @_);
}

sub DESTROY
{
	my $self = @_ ? shift : &Azzert ();
	
	my $ks  = 'rfnOnDestroy';
	my $rfn = $self->{$ks};
	
	if (defined ($rfn))
	{
		&Azzert (ref $rfn eq 'CODE');
		$rfn->($self, @_);
	}
}

1;
}


{
package Config;
DestroyGuard->import ();
Util        ->import ();
use strict; use warnings;

sub CreateObject
{
	my $sClassName = @_ ? shift : &Azzert ();
	
	my $sMachineName;
	{
		use POSIX qw (strftime);
		my @aiTimeParts = localtime ();
		$sMachineName = strftime ('%y%m%d-%H%M_SyndiVM', @aiTimeParts);
	}
	
	my $self =
	{
		'iDebugLevel'  => 0,
		'sMachineName' => $sMachineName,
		'sOSType'      => 'Debian_64',
		'nmibMemory'   => 512,
		'nCPUCores'    => 1,
		'nFunDisks'    => 2
	};
	
	return bless ($self, $sClassName);
}

sub DebugLevel  { return &GetOrSetObjectProperty ('iDebugLevel' , @_); }
sub MachineName { return &GetOrSetObjectProperty ('sMachineName', @_); }
sub OSType      { return &GetOrSetObjectProperty ('sOSType'     , @_); }
sub NrMiBMemory { return &GetOrSetObjectProperty ('nmibMemory'  , @_); }
sub NrCPUCores  { return &GetOrSetObjectProperty ('nCPUCores'   , @_); }
sub NrFunDisks  { return &GetOrSetObjectProperty ('nFunDisks'   , @_); }

sub ProcessCmdLine
{
	my $self = @_ ? shift : &Azzert ();
	
	my $nsArgs = scalar (@_);
	
	my $sPending;
	my $isArg  = 0;
	foreach my $sArg (@_)
	{
		if (defined ($sPending))
		{
			if    ($sPending =~ m/^debug(-level)$/  ) { $self->DebugLevel  ($sArg); }
			elsif ($sPending =~ m/^(machine-)?name$/) { $self->MachineName ($sArg); }
			elsif ($sPending =~ m/^os-type$/        ) { $self->OSType      ($sArg); }
			elsif ($sPending =~ m/^memory(-size)?$/ ) { $self->NrMiBMemory ($sArg); }
			elsif ($sPending =~ m/^(nr-)?cores$/    ) { $self->NrCPUCores  ($sArg); }
			elsif ($sPending =~ m/^(nr-)fun-disks$/ ) { $self->NrFunDisks  ($sArg); }
			else                                      { &Azzert (0); }
			
			$sPending = undef;
		}
		else
		{
			if ($sArg =~ m/^-+(.*)$/)
			{
				my $sOption = $1;
				
				if    ($sOption =~ m/^(debug(-level)|(machine-)?name|os-type|memory(-size)?|(nr-)?cores|(nr-)?fun-disks)$/)
				{
					$sPending = $sOption;
				}
				else
				{
					printf_2 ("Error: Unexpected option: %s.\n", "`${sArg}`");
					return 0;
				}
			}
			else
			{
				printf_2 ("Error: Unexpected cmdline arg: %s.\n", "`${sArg}`");
				return 0;
			}
		}
	}
	continue
	{
		++$isArg;
	}
	
	return 1;
}

sub ToString
{
	my $self = @_ ? shift : &Azzert ();
	
	return join (', ', map { sprintf ('%s %s', $_, $self->{$_}); } sort keys %$self);
}

1;
}


package main;
Config      ->import ();
DestroyGuard->import ();
Util        ->import ();
use strict; use warnings;

## [2022-07-09]
##   This Perl script is based on the `Go` Bash script.

## [2019-11-19]
## 
##   This script should be in the folder with VirtualBox virtual machines.
##   
##   After having run it, please modify the generated .vbox file:
##     Change
##       <Logo fadeIn="true" fadeOut="true" displayTime="0" imagePath="Isabeau-1-cropped.bmp"/>
##     to
##       <Logo fadeIn="true" fadeOut="true" displayTime="0" imagePath="G:/VM_G/191119-015328_Deborah/Isabeau-1-cropped.bmp"/>
##     (of course, replacing with the full pathname of where the image resides).
##     This enables the boot logo image.


sub Main
{
	my $config = Config->CreateObject ();
	{
		my $bResult = $config->ProcessCmdLine (@_);
		if (! $bResult)
		{
			printf_2 ("Error: Config::ProcessCmdLine has failed !!\n");
			exit (130);
		}
	}
	
	if (1)
	{
		printf ("## Config: %s.\n", $config->ToString ());
	}
	
	my ($stimeNow) = @_;
	{
		if (! $stimeNow)
		{
			$stimeNow = `date +"%y%m%d-%H%M"`;
			chomp ($stimeNow);
		}
	}
	
	my $stimeUse = $stimeNow;
	
	my $sName = "${stimeUse}_SyndiVM";
	
	my $sVBoxManage = "VBoxManage";
	
	if (-d "${sName}/")
	{
		print ("## Unregistering machine \"${sName}\"...\n");
		print ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { print ("## }\n\n"); });
		print ("${sVBoxManage} unregistervm \"${sName}\" || true\n");
		print ("mv \"${sName}/\" \"${sName}_${stimeUse}/\"\n");
	}
	
	if (1)
	{
		print ("## Creating machine \"${sName}\"...\n");
		print ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { print ("## }\n\n"); });
		print ("${sVBoxManage} createvm --name \"${sName}\" --ostype \"Debian_64\" --register\n");
	}
	
	if (1)
	{
		print ("## Showing...\n");
		print ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { print ("## }\n\n"); });
		print ("${sVBoxManage} showvminfo \"${sName}\"\n");
	}
	
	if (1)
	{
		print ("## Modifying...\n");
		print ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { print ("## }\n\n"); });
		print
		(
			"${sVBoxManage} modifyvm \"${sName}\" \\\n" .
			"    --memory                     2048                            \\\n" .
			"    --vram                         32                            \\\n" .
			"    --ioapic                     on                              \\\n" .
			"    --rtcuseutc                  on                              \\\n" .
			"    --cpus                          2                            \\\n" .
			"    --accelerate2dvideo          off                             \\\n" .
			"    --accelerate3d               on                              \\\n" .
			"    \\\n" .
			"    --clipboard                  bidirectional                   \\\n" .
			"    --draganddrop                bidirectional                   \\\n" .
			"    \\\n" .
			"    --bioslogoimagepath          \"Media/Isabeau-1-cropped.bmp\"   \\\n" .
			"    --boot1                      none                            \\\n" .
			"    --boot2                      dvd                             \\\n" .
			"    --boot3                      disk                            \\\n" .
			"    --boot4                      none                            \\\n" .
			"\n" .
			"${sVBoxManage} storagectl \"${sName}\" --name \"IDE\"  --add \"ide\"\n" .
			"${sVBoxManage} storagectl \"${sName}\" --name \"SATA\" --add \"sata\"\n"
		);
	}
	
	if (1)
	{
		print ("## Disks:\n");
		
		## [2020-08-24]
		## 
		##   Setup of storage:
		##   
		##     We are creating multiple 1-TiB disks.
		##     No need to worry: VirtualBox is only going to save the part which is actually used.
		##     
		##     Each disk should have a single partition, initially of a much smaller size (e.g. 16 GiB or 32 GiB for the root partition).
		##     
		##     This is (I believe) a better setup than multiple partitions on a single disk:
		##     it allows lean-and-mean backups
		##     (including backups of individual partitions,
		##     because they are reside on separate virtual disk files).
		##     
		##     This setup also allows us to grow the partitions easily when needed:
		##     we can boot the virtual machine from a Linux optical disk image and (install and) run gparted
		##     and increase the size of any partition (because there is space up to 1 TiB on the virtual disk).
		##     
		##     This setup also allows us to make the swap partition immutable:
		##     its virtual disk need not occupy space when the virtual machine is powered off.
		
		my @arasDisks = map
		{
			[$_, 2097152, "normal"]
		}
		(
			"Root", "Swap", "Home", "Fun0", "Fun1"
		);
		
		my $iDisk = 0;
		foreach my $rasDisk (@arasDisks)
		{
			my ($sDiskName, $nDiskSize, $sDiskType) = @$rasDisk;
			printf ("## Disk %2u (\"/dev/sd%s\" ?): %-16s %10u %s.\n", $iDisk, chr (ord ("a") + $iDisk), $sDiskName, $nDiskSize, $sDiskType);
			printf ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { printf ("## }\n\n"); });
			
			print ("${sVBoxManage} closemedium  disk '${sName}/${sDiskName}.vdi' --delete &>/dev/null || true\n");
			print ("${sVBoxManage} createmedium disk --format 'VDI' --variant 'Standard' --filename '${sName}/${sDiskName}.vdi' --size '${nDiskSize}'\n");
			print ("${sVBoxManage} storageattach '${sName}' --storagectl 'SATA' --port '${iDisk}' --type 'hdd' --medium '${sName}/${sDiskName}.vdi' --mtype '${sDiskType}'\n");
		}
		continue
		{
			++$iDisk;
		}
		
		print ("\n");
	}
	
	print (<<'EOF');
cat <<-'EOF_BASH'
	The virtual machine sub-folder has been created in the folder configured for VirtualBox.
	
	But the sub-folder with the disks is in the current folder.
	
	In order to move the disks, we have to:
	  - start VirtualBox without starting the virtual machine;
	  - navigate to (Menu) -> "File" (or the Global Tools toolbar button) -> "Tools" -> "Virtual Media Manager";
	  - make sure the "Hard disks" tab is selected;
	  - right-click each individual disk and (from the popup menu) select "Move...".
	
	Alternatively, we can:
	  - move all disks to the virtual machine sub-folder;
	  - modify the `<HardDisk.../>` lines in the `.vbox` file (so they only specify the relative pathname).
	
	In order to enable the boot logo image, we have to modify the generated `.vbox` file:
	
	  We change:
	  
	    ```
	    <Logo fadeIn="true" fadeOut="true" displayTime="0" imagePath="Isabeau-1-cropped.bmp"/>
	    ```
	  
	  to
	  
	    ```
	    <Logo fadeIn="true" fadeOut="true" displayTime="0" imagePath="G:/VM_G/191119-015328_Deborah/Isabeau-1-cropped.bmp"/>
	    ```
	  
	  (of course, using the full pathname of where the image actually resides on our computer).
	
	EOF_BASH
EOF
	
	print ("\n\n");
	
	return 1;
}

if (! &Main (@ARGV))
{
	{ use IO::Handle; STDOUT->flush (); STDERR->flush (); }
	die ("The `Main` subroutine has failed !\n");
}
