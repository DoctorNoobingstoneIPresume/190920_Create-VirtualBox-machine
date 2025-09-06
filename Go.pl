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
	QuoteArg QuoteArgs
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

sub QuoteArg
{
	my $sArg = @_ ? shift : &Azzert ();
	
	if (! length ($sArg) || $sArg =~ m#[[:space:]\\\'\"\`\!\@\$\&\*\?(){}<>]#)
	{
		$sArg =~ s#\'#\'\\\'\'#g;
		$sArg = "'${sArg}'";
	}
	
	return $sArg;
}

sub QuoteArgs
{
	my $rasArgs = @_ ? shift : &Azzert (); { Azzert (ref $rasArgs eq 'ARRAY'); }
	return join (' ', map { &QuoteArg ($_); } @$rasArgs);
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
	my $stimeUse   = @_ ? shift : sub { use POSIX qw (strftime); my @ai = localtime (); return strftime ('%y%m%d-%H%M', @ai); }->();
	
	my $self =
	{
		'iHelpLevel'   => 0,
		'iDebugLevel'  => 0,
		'sMachineName' => "${stimeUse}_SyndiVM",
		'sOSType'      => 'Debian_64',
		'nmibMemory'   => 512,
		'nmibVRAM'     => 16,
		'nThreads'     => 1,
		'nFunDisks'    => 2
	};
	
	return bless ($self, $sClassName);
}

sub HelpLevel   { return &GetOrSetObjectProperty ('iHelpLevel'  , @_); }
sub DebugLevel  { return &GetOrSetObjectProperty ('iDebugLevel' , @_); }
sub MachineName { return &GetOrSetObjectProperty ('sMachineName', @_); }
sub OSType      { return &GetOrSetObjectProperty ('sOSType'     , @_); }
sub NrMiBMemory { return &GetOrSetObjectProperty ('nmibMemory'  , @_); }
sub NrMiBVRAM   { return &GetOrSetObjectProperty ('nmibVRAM'    , @_); }
sub NrThreads   { return &GetOrSetObjectProperty ('nThreads'    , @_); }
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
			if    ($sPending =~ m/^help-level$/                ) { $self->HelpLevel   ($sArg); }
			elsif ($sPending =~ m/^debug(-level)$/             ) { $self->DebugLevel  ($sArg); }
			elsif ($sPending =~ m/^(machine-)?name$/           ) { $self->MachineName ($sArg); }
			elsif ($sPending =~ m/^os-type$/                   ) { $self->OSType      ($sArg); }
			elsif ($sPending =~ m/^memory(-size)?$/            ) { $self->NrMiBMemory ($sArg); }
			elsif ($sPending =~ m/^vram(-size)?$/              ) { $self->NrMiBVRAM   ($sArg); }
			elsif ($sPending =~ m/^(nr-)?(cpus|cores|threads)$/) { $self->NrCPUCores  ($sArg); }
			elsif ($sPending =~ m/^(nr-)fun-disks$/            ) { $self->NrFunDisks  ($sArg); }
			else                                                 { &Azzert (0); }
			
			$sPending = undef;
		}
		else
		{
			if ($sArg =~ m/^-+(.*)$/)
			{
				my $sOption = $1;
				
				if    ($sOption =~ m/^(help-level|debug(-level)|(machine-)?name|os-type|memory(-size)?|vram(-size)?|(nr-)?(cpus|cores|threads)|(nr-)?fun-disks)$/)
				{
					$sPending = $sOption;
				}
				elsif ($sOption =~ m/^help$/)
				{
					$self->HelpLevel (1);
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
	
	my @aras =
	(
		['help-level'  , $self->HelpLevel   ()],
		['debug-level' , $self->DebugLevel  ()],
		['machine-name', $self->MachineName ()],
		['os-type'     , $self->OSType      ()],
		['memory'      , $self->NrMiBMemory ()],
		['vram'        , $self->NrMiBVRAM   ()],
		['nr-threads'  , $self->NrThreads   ()],
		['nr-fun-disks', $self->NrFunDisks  ()]
	);
	
	return join
	(
		'  ',
		map
			{ &QuoteArg ('--' . $_->[0]) . ' ' . &QuoteArg ($_->[1]) }
			@aras
	);
}

sub HelpMessage
{
	my $self = @_ ? shift : &Azzert ();
	
	return sprintf ('%s', <<EOT);
This script outputs a Bash script which, if executed,
invokes VBoxManage in order to generate a new Virtual Machine
configured as requested.

Options:

    --help-level <n>
        Selects the help level.
        If the help level is non-zero:
          - this helpful help message is displayed;
          - normal execution is not performed.

    --help
        Sets the help level to 1.

    --debug-level <n>
        Selects the debug (verbosity) level.
        (Currently, this is not used in any way.)

    --machine-name <value>
        Sets the name of the Virtual Machine.

    --os-type <value>
        Sets the Operating System name.

    --memory <n>
        Sets the size of the Memory for the Virtual Machine (in MiB).

    --vram <n>
        Sets the size of the VRAM (Video Memory) for the Virtual Machine (in MiB).

    --nr-threads <n>
        Sets the number of Threading Units for the Virtual Machine.
        If the Real Machine CPU has Hyper-Threading:
          each Core counts as two Threading Units.

    --nr-fun-disks <n>
        Sets the number of extra disks
        (besides the normal disks: `root`, `swap`, `home`).

The command-line arguments which would generate the current `Config`
are helpfully output (as a shell comment).

We hope that you have lots of fun in using this script !!
>:D<


EOT

}

1;
}


{
package Disk;
Util->import ();
use strict; use warnings;

sub CreateObject
{
	my $sClassName = @_ ? shift : &Azzert ();
	
	my $self =
	{
		'sName'    => @_ ? shift : 'Untitled Disk',
		'nmibSize' => @_ ? shift : 2097152,
		'sType'    => @_ ? shift : 'normal'
	};
	
	return bless ($self, $sClassName);
}

sub Name      { return &GetOrSetObjectProperty ('sName'   , @_); }
sub NrMiBSize { return &GetOrSetObjectProperty ('nmibSize', @_); }
sub Type      { return &GetOrSetObjectProperty ('sType'   , @_); }

sub ToString
{
	my $self = @_ ? shift : &Azzert ();
	
	return sprintf
	(
		'name %-16s, size-in-MiB %9u, type %-16s',
		"'" . $self->Name      () . "'",
		      $self->NrMiBSize (),
		"'" . $self->Type      () . "'"
	);
}

1;
}

package main;
Disk        ->import ();
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
	my $stimeNow;
	{
		use POSIX qw (strftime);
		my @aiTimeParts = localtime ();
		$stimeNow = strftime ('%y%m%d-%H%M', @aiTimeParts);
	}
	
	my $stimeUse = $stimeNow;
	
	my $config = Config->CreateObject ($stimeUse);
	{
		my $bResult = $config->ProcessCmdLine (@_);
		if (! $bResult)
		{
			printf_2 ("Error: Config::ProcessCmdLine has failed !!\n");
			exit (130);
		}
	}
	
	if ($config->HelpLevel ())
	{
		printf ("%s\n", $config->HelpMessage ());
	}
	
	if (1)
	{
		printf ("## Config: %s.\n", $config->ToString ());
	}
	
	if ($config->HelpLevel ())
	{
		return 1;
	}
	
	my $sName = $config->MachineName ();
	
	my $sVBoxManage = "VBoxManage";
	
	if (-d "${sName}/")
	{
		printf ("## Unregistering machine %s...\n", &QuoteArg ($sName));
		printf ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { printf ("## }\n\n"); });
		
		printf
		(
			"%s unregistervm %s || true\n",
			&QuoteArg ($sVBoxManage),
			&QuoteArg ($sName)
		);
		
		printf
		(
			"mv %s %s\n",
			&QuoteArg ("${sName}/"),
			&QuoteArg ("${sName}_${stimeUse}/")
		);
	}
	
	if (1)
	{
		printf ("## Creating machine %s...\n", &QuoteArg ($sName));
		printf ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { printf ("## }\n\n"); });
		
		printf
		(
			"%s createvm --name %s --ostype %s --register\n",
			&QuoteArg ($sVBoxManage),
			&QuoteArg ($sName),
			&QuoteArg ('Debian_64')
		);
	}
	
	if (1)
	{
		printf ("## Showing machine %s...\n", &QuoteArg ($sName));
		printf ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { printf ("## }\n\n"); });
		
		printf
		(
			"%s showvminfo %s\n",
			&QuoteArg ($sVBoxManage),
			&QuoteArg ($sName)
		);
	}
	
	if (1)
	{
		printf ("## Modifying...\n");
		printf ("## {\n"); my $g0 = DestroyGuard->CreateObject (sub { printf ("## }\n\n"); });
		
		my $sModifyOptions = '';
		{
			my @aras =
			(
				['--memory'             , $config->NrMiBMemory ()      ],
				['--vram'               , $config->NrMiBVRAM   ()      ],
				['--ioapic'             , 'on'                         ],
				['--rtcuseutc'          , 'on'                         ],
				['--cpus'               , $config->NrThreads   ()      ],
				['--accelerate2dvideo'  , 'off'                        ],
				['--accelerate3d'       , 'on'                         ],
				['--clipboard'          , 'bidirectional'              ],
				['--draganddrop'        , 'bidirectional'              ],
				['--bioslogoimagepath'  , 'Media/Isabeau-1-cropped.bmp'],
				['--boot1'              , 'none'                       ],
				['--boot2'              , 'dvd'                        ],
				['--boot3'              , 'disk'                       ],
				['--boot4'              , 'none'                       ]
			);
			
			use List::Util qw (reduce max);
			
			my @accmax =
				map
				{
					my $index = $_;
					
					reduce
					{
						max ($a, length (&QuoteArg ($b->[$index])))
					}
					(0, @aras)
				}
				(0, 1);
			
			$sModifyOptions = join
			(
				" \\\n",
				map
				{
					sprintf
					(
						'    %-*s %-*s',
						$accmax [0], &QuoteArg ($_->[0]),
						$accmax [1], &QuoteArg ($_->[1])
					)
				}
				(@aras)
			);
		}
		
		printf
		(
			"%s modifyvm %s \\\n%s\n\n",
			&QuoteArg ($sVBoxManage),
			&QuoteArg ($sName),
			$sModifyOptions
		);
		
		{
			my @aras =
			(
				['IDE' , 'ide' ],
				['SATA', 'sata']
			);
			
			use List::Util qw (reduce max);
			
			my @accmax =
				map
				{
					my $index = $_;
					reduce
					{
						max ($a, length (&QuoteArg ($b->[$index])))
					}
					(0, @aras)
				}
				(0, 1);
			
			printf
			(
				'%s',
				join
				(
					'',
					map
					{
						sprintf
						(
							"%s storagectl %s --name %-*s --add %-*s\n",
							&QuoteArg ($sVBoxManage),
							&QuoteArg ($sName),
							$accmax [0], &QuoteArg ($_->[0]),
							$accmax [1], &QuoteArg ($_->[1])
						)
					}
					(@aras)
				)
			);
		}
	}
	
	if (1)
	{
		printf ("## Disks:\n{\n"); my $g0 = DestroyGuard->CreateObject (sub { printf ("}\n\n"); });
		
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
		
		my @asDiskNames = ('Root', 'Swap', 'Home');
		{
			use List::Util qw (min);
			for (my ($i, $n) = (0, min ($config->NrFunDisks (), 16)); $i < $n; ++$i)
			{
				push (@asDiskNames, sprintf ('Fun_%02Xh', $i));
			}
		}
		
		my @arDisks = map
		{
			Disk->CreateObject ($_, 2 * 1024 * 1024, 'normal')
		}
		(@asDiskNames);
		
		my $rfnMakeDiskFullName = sub
		{
			my $sDiskName = @_ ? shift : &Azzert ();
			return "${sName}/${sDiskName}.vdi";
		};
		
		use List::Util qw (reduce max);
		my $ccmaxDiskFullName =
			reduce
			{
				max ($a, length (&QuoteArg ($rfnMakeDiskFullName->($b->Name ()))))
			}
			(32, @arDisks);
		
		for (my $iDisk = 0; $iDisk < scalar (@arDisks); ++$iDisk)
		{
			my $rDisk = $arDisks [$iDisk];
			
			my $sDiskName     = $rDisk->Name      ();
			my $nDiskSize     = $rDisk->NrMiBSize ();
			my $sDiskType     = $rDisk->Type      ();
			my $sDiskFullName = $rfnMakeDiskFullName->($sDiskName);
			
			printf ("## Disk %2u ('/dev/sd%s' ?!): %s.\n", $iDisk, chr (ord ('a') + $iDisk), $rDisk->ToString ());
			printf ("## {\n"); my $g1 = DestroyGuard->CreateObject (sub { printf ("## }\n\n"); });
			
			printf
			(
				"%s closemedium   disk %-*s --delete &>/dev/null || true\n",
				&QuoteArg ($sVBoxManage),
				$ccmaxDiskFullName, &QuoteArg ($sDiskFullName)
			);
			
			printf
			(
				"%s createmedium  disk --format %s --variant %s --filename %-*s --size %9u\n",
				&QuoteArg ($sVBoxManage),
				&QuoteArg ('VDI'),
				&QuoteArg ('Standard'),
				$ccmaxDiskFullName, &QuoteArg ($sDiskFullName),
				&QuoteArg ($nDiskSize)
			);
			
			printf
			(
				"%s storageattach %s --storagectl %s --port %2u --type %s --medium %-*s --mtype %s\n",
				&QuoteArg ($sVBoxManage),
				&QuoteArg ($sName),
				&QuoteArg ('SATA'),
				&QuoteArg ($iDisk),
				&QuoteArg ('hdd'),
				$ccmaxDiskFullName, &QuoteArg ($sDiskFullName),
				&QuoteArg ($sDiskType)
			);
		}
		
		printf ("\n");
	}
	
	printf ('%s', <<'EOF');
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
	
	printf ("\n\n");
	
	return 1;
}

if (! &Main (@ARGV))
{
	{ use IO::Handle; STDOUT->flush (); STDERR->flush (); }
	die ("The `Main` subroutine has failed !\n");
}
