package Apache::Ocsinventory::Plugins::Userinstalledapps::Map;
 
use strict;
 
use Apache::Ocsinventory::Map;

$DATA_MAP{userinstalledapps} = {
	mask => 0,
	multi => 1,
	auto => 1,
	delOnReplace => 1,
	sortBy => 'PATH',
	writeDiff => 0,
	cache => 0,
	fields => {
		USERNAME => {},
		APPNAME => {},
		PUBLISHER => {},
		VERSION => {}
	}
};
1;