#!/usr/bin/env perl
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
		print ("${sVBoxManage} unregistervm \"${sName}\" || true\n");
		print ("mv \"${sName}/\" \"${sName}_${stimeUse}/\"\n");
		print ("\n");
	}
	
	if (1)
	{
		print ("## Creating machine \"${sName}\"...\n");
		print ("${sVBoxManage} createvm --name \"${sName}\" --ostype \"Debian_64\" --register\n");
		print ("\n");
	}
	
	if (1)
	{
		print ("## Showing...\n");
		print ("${sVBoxManage} showvminfo \"${sName}\"\n");
		print ("\n");
	}
	
	if (1)
	{
		print ("## Modifying...\n");
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
			"${sVBoxManage} storagectl \"${sName}\" --name \"SATA\" --add \"sata\"\n" .
			"\n"
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
			[$_, 1572864, "normal"]
		}
		(
			"Root", "Swap", "Home", "Fun0", "Fun1"
		);
		
		my $iDisk = 0;
		foreach my $rasDisk (@arasDisks)
		{
			my ($sDiskName, $nDiskSize, $sDiskType) = ($$rasDisk [0], $$rasDisk [1], $$rasDisk [2]);
			printf ("## Disk %2u (\"/dev/sd%s\" ?): %-16s %10u %s.\n", $iDisk, chr (ord ("a") + $iDisk), $sDiskName, $nDiskSize, $sDiskType);
			
			print ("${sVBoxManage} closemedium  disk \"${sName}/${sDiskName}.vdi\" --delete >/dev/null 2>&1 || true\n");
			print ("${sVBoxManage} createmedium disk --format \"VDI\" --variant \"Standard\" --filename \"${sName}/${sDiskName}.vdi\" --size \"${nDiskSize}\"\n");
			print ("${sVBoxManage} storageattach \"${sName}\" --storagectl \"SATA\" --port \"${iDisk}\" --type \"hdd\" --medium \"${sName}/${sDiskName}.vdi\" --mtype \"${sDiskType}\"\n");
			
			print ("\n");
			
			++$iDisk;
		}
		
		print ("\n");
	}
	
	print << 'EOF';
echo
echo 'The virtual machine sub-folder has been created in the folder configured for VirtualBox.'
echo ''
echo 'But the sub-folder with the disks is in the current folder.'
echo 'In order to move the disks:'
echo '  - please start VirtualBox without starting the virtual machine;'
echo '  - go to (Menu) -> "File" (or the Global Tools toolbar button) -> "Virtual Media Manager";'
echo '  - make sure the Hard disks tab is selected;'
echo '  - right-click each individual disk and from the popup menu select "Move...".'
echo 'Alternative:'
echo '  - move all disks to the virtual machine sub-folder;'
echo '  - modify the <HardDisk.../> lines in the .vbox file.'
echo ''
echo 'Also, in order to enable the boot logo image, please modify the generated .vbox file:'
echo '    Change'
echo '        <Logo fadeIn="true" fadeOut="true" displayTime="0" imagePath="Isabeau-1-cropped.bmp"/>'
echo '    to'
echo '        <Logo fadeIn="true" fadeOut="true" displayTime="0" imagePath="G:/VM_G/191119-015328_Deborah/Isabeau-1-cropped.bmp"/>'
echo '        (of course, replacing with the full pathname of where the image resides).'
echo
echo
echo
EOF
	;
	
	print ("\n\n");
	
	return 1;
}

if (! &Main (@ARGV))
{
	{ use IO::Handle; STDOUT->flush (); STDERR->flush (); }
	die ("The `Main` subroutine has failed !\n");
}
