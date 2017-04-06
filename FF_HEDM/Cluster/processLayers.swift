#
# Copyright (c) 2014, UChicago Argonne, LLC
# See LICENSE file.
#

type file;

app (file ep) runPeaks (string paramsfn, int fnr, int ringnr)
{
	peaks paramsfn fnr ringnr stderr=filename(ep);
}

app (file err) runProcessPeaks (string paramsf, int RNr, file DummyA[])
{
	processPeaks paramsf RNr stderr=filename(err);
}

app (file err) mergerings (string pfname, file dummy[])
{
	mergeRings pfname stderr=filename(err);
}

app (file err, file spotsfile) postpeaks (string foldername, string pfname, file dummy)
{
	postPeaks foldername pfname filename(spotsfile) stderr=filename(err);
}

app (file err, file spotsfile) postpeaks2 (string foldername, string pfname)
{
	postPeaks foldername pfname filename(spotsfile) stderr=filename(err);
}

app (file err) indexrefine (string foldername, int spotsinput, file dm)
{
	indexstrains spotsinput foldername stderr=filename(err);
}

app (file out) processgrains (string foldername, string pfname, file dummy[])
{
	processGrains foldername pfname stdout=filename(out);
}

# Parameters to be modified #############

int startnr = toInt(arg("startnr","1"));
int endnr = toInt(arg("endnr","600"));
string ringfile = arg("ringfile","RingInfo.txt");
string seedfolder = arg("SeedFolder","/clhome/FolderNames.txt");
int dopeaksearch = toInt(arg("DoPeakSearch","1"));

# End parameters ########################

int rings[] = readData(ringfile);
string folderNames[] = readData(strcat(seedfolder,"/FolderNames.txt"));
string PFNames[] = readData(strcat(seedfolder,"/PFNames.txt"));

if (dopeaksearch == 1) {
	###### Change to iterate instead of foreach
	iterate ix {
		string foldername = folderNames[ix];
		string paramfilenamefile = strcat(foldername,"/ParamFileNames.txt");
		string paramFileNames[] = readData(paramfilenamefile);
		file simBerr[]<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat("ProcessPeaks_",ix,"_"),suffix=".err">;
		file simAerr[];
		foreach Ring,idx in rings {
			string parameterfilename = paramFileNames[idx];
			string PreFix1 = strcat("PeaksPerFile_",Ring);
			foreach i in [startnr:endnr] {
				file simx<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat(PreFix1,"_",i,"_"),suffix=".err">;
				simx = runPeaks(parameterfilename,i,Ring);
				if (i %% 100 == 0){
					int simAidx = (i%/100) + idx*(endnr%/100);
					simAerr[simAidx] = simx;
				}
			}
		}
		foreach Ring2,idx2 in rings {
			string parameterfilename = paramFileNames[idx2];
			simBerr[idx2] = runProcessPeaks(parameterfilename,Ring2,simAerr);
		}
		# take the output of this, run mergemultiple rings for each layer
		string pfname = PFNames[ix];
		file simCerr<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat("MergeRings_",ix),suffix=".err">;
		simCerr = mergerings(pfname, simBerr);
		# take the output, run shmoperators
		file simDerr<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat("PostPeaksSHM_",ix),suffix=".err">;
		file simCatOut<single_file_mapper;file=strcat(foldername,"SpotsToIndex.csv")>;
		(simDerr,simCatOut) = postpeaks(foldername,pfname,simCerr);
		int spots[] = readData(simCatOut);
		trace(spots);
		file allFile[];
		foreach spotnr in spots {
			file simEerr<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat("IndexRefine_",ix,"_",spotnr),suffix=".err">;
			simEerr = indexrefine(foldername,spotnr,simCatOut);
			trace(spotnr);
			if (spotnr %% 100 == 0){
				allFile[spotnr %/ 100] = simEerr;
			}
		}
		file processgrainsout <single_file_mapper;file=strcat(foldername,"/output/processgrains.txt")>;
		processgrainsout = processgrains(foldername,pfname,allFile);
	#}
	} until (ix == length(folderNames));
} else {
	###### Change to iterate instead of foreach
	iterate ix {
	#foreach foldername,ix in folderNames { 
		string foldername = folderNames[ix];
		string pfname = PFNames[ix];
		# equivalent to layernr
		file simDerr<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat("PostPeaksSHM_",ix),suffix=".err">;
		file simCatOut<single_file_mapper;file=strcat(foldername,"SpotsToIndex.csv")>;
		(simDerr,simCatOut) = postpeaks2(foldername,pfname);
		int spots[] = readData(simCatOut);
		file allFile2[];
		foreach i in spots {
			file simEerr<simple_mapper;location=strcat(foldername,"/output"),prefix=strcat("IndexRefine_",ix,"_",i),suffix=".err">;
			simEerr = indexrefine(foldername,i,simCatOut);
			if (i %% 100 == 0){
				allFile2[i %/ 100] = simEerr;
			}
		}
		file processgrainsout <single_file_mapper;file=strcat(foldername,"/output/processgrains.txt")>;
		processgrainsout = processgrains(foldername,pfname,allFile2);
	#}
	} until (ix == length(folderNames));
}
