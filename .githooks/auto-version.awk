BEGIN { incremented = 0; }

{
	if (match($0, /@[0-9]+(\.[0-9]+)*/))
	{
		before  = substr($0, 1, RSTART - 1);
		version = substr($0, RSTART + 1, RLENGTH - 1);
		after   = substr($0, RSTART + RLENGTH);
		split(version, parts, ".");
		version_major = parts[1] + 0;
		version_minor = parts[2] + 0;
		version_patch = parts[3] + 0;
		version_patch += 1;
		version = (version_major "." version_minor "." version_patch);
		incremented = 1;
		print (before "@" version after);
	}
	else { print; }
}

END { exit(!incremented); }
