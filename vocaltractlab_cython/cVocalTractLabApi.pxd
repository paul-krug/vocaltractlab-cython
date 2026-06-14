#cdef extern from "VocalTractLabApi.h":
#    int vtlCalcTongueRootAutomatically(bool automaticCalculation);
#    void vtlGetVersion(char *version);
#    int vtlInitialize(const char *speakerFileName);
#    int vtlClose();
#    int vtlGetConstants(int *audioSamplingRate, int *numTubeSections, int *numVocalTractParams, int *numGlottisParams);


#cdef extern from "VocalTractLabApi.cpp":
#    pass

cdef extern from "VocalTractLabApi.h":

    ctypedef enum SpectrumType:
        NO_RADIATION,
        PISTONINSPHERE_RADIATION,
        PISTONINWALL_RADIATION,
        PARALLEL_RADIATION,
        NUM_RADIATION_OPTIONS,

    ctypedef enum RadiationType:
        SPECTRUM_UU,
        SPECTRUM_PU,

    ctypedef struct TransferFunctionOptions:
        SpectrumType spectrumType
        RadiationType radiationType
        bint boundaryLayer
        bint heatConduction
        bint softWalls
        bint hagenResistance
        bint innerLengthCorrections
        bint lumpedElements
        bint paranasalSinuses
        bint piriformFossa
        bint staticPressureDrops

    int vtlCalcTongueRootAutomatically( bint automaticCalculation )

    int vtlClose()

    int vtlExportTractSvg(
        double *tractParams,
        const char *fileName,
        )

    int vtlExportTractSvgToStr(
        double *tractParams,
        const char *svgStr,
        )

    int vtlGesturalScoreToAudio(
        const char *gesFileName,
        const char *wavFileName,
        double *audio,
        int *numSamples,
        bint enableConsoleOutput,
        )

    int vtlGesturalScoreToTractSequence(
        const char *gesFileName, 
        const char *tractSequenceFileName,
        )

    int vtlGetConstants(
        int *audioSamplingRate,
        int *numTubeSections,
        int *numVocalTractParams,
        int *numGlottisParams,
        int *numAudioSamplesPerTractState,
        double *internalSamplingRate,
        )

    int vtlGetDefaultTransferFunctionOptions( TransferFunctionOptions *opts )

    int vtlGetGesturalScoreDuration(
        const char *gesFileName,
        int *numAudioSamples,
        int *numGestureSamples,
        )

    int vtlGetGlottisParamInfo(
        char *names,
        char *descriptions,
        char *units,
        double *paramMin,
        double *paramMax,
        double *paramStandard,
        )

    int vtlGetTractParamInfo(
        char *names,
        char *descriptions,
        char *units,
        double *paramMin,
        double *paramMax,
        double *paramStandard,
        )

    int vtlGetGlottisParams(
        const char *shapeName,
        double *glottisParams,
        )

    int vtlGetTractParams(
        const char *shapeName,
        double *tractParams,
        )

    int vtlGetTransferFunction(
        double *tractParams,
        int numSpectrumSamples,
        TransferFunctionOptions *opts,
        double *magnitude,
        double *phase_rad
        )

    void vtlGetVersion( char *version )

    int vtlInitialize( const char *speakerFileName )

    int vtlInputTractToLimitedTract(
        double *inTractParams,
        double *outTractParams
        )

    int vtlSegmentSequenceToGesturalScore(
        const char *segFileName,
        const char *gesFileName,
        bint enableConsoleOutput,
        )

    int vtlSynthBlock(
        double *tractParams,
        double *glottisParams,
        int numFrames,
        int frameStep_samples,
        double *audio,
        bint enableConsoleOutput,
        )

    int vtlTractSequenceToAudio(
        const char *tractSequenceFileName,
        const char *wavFileName,
        double *audio,
        int *numSamples,
        )

    int vtlTractToTube(
        double *tractParams,
        double *tubeLength_cm,
        double *tubeArea_cm2,
        int *tubeArticulator,
        double *incisorPos_cm,
        double *tongueTipSideElevation,
        double *velumOpening_cm2
        )

    int vtlFastTractToTube(
        double *tractParams,
        double *tubeLength_cm,
        double *tubeArea_cm2,
        int *tubeArticulator,
        double *incisorPos_cm,
        double *tongueTipSideElevation,
        double *velumOpening_cm2
        )

    int vtlTractToFullTube(
        double *tractParams,
        double *tubeLength_cm,
        double *tubeArea_cm2,
        double *tubeVolume_cm3,
        double *tubeWallMass_cgs,
        double *tubeWallStiffness_cgs,
        double *tubeWallResistance_cgs,
        int *tubeArticulator,
        double *incisorPos_cm,
        double *tongueTipSideElevation,
        double *velumOpening_cm2,
        double *piriformFossaLength_cm,
        double *piriformFossaVolume_cm3
        )

    int vtlGlottisCalcGeometry(
        double *controlParams,
        double *derivedParams,
        int *numDerivedParams,
        double *tubeLength_cm,
        double *tubeArea_cm2,
        )

    int vtlGlottisIncTime(
        double timeIncrement_s,
        double *pressure_dPa,
        double *controlParams,
        double *derivedParams,
        int *numDerivedParams,
        double *tubeLength_cm,
        double *tubeArea_cm2,
        )

    int vtlGlottisResetMotion()

    int vtlGetGlottisStaticParamInfo(
        char *names,
        double *paramMin,
        double *paramMax,
        double *paramStandard,
        int *numStaticParams,
        )

    int vtlSynthesisReset()

    int vtlSynthesisAddTube(
        int numNewSamples,
        double *audio,
        double *tubeLength_cm,
        double *tubeArea_cm2,
        int *tubeArticulator,
        double incisorPos_cm,
        double velumOpening_cm2,
        double tongueTipSideElevation,
        double *newGlottisParams,
        )

    int vtlTdsSetOptions(
        bint generateNoiseSources,
        bint turbulenceLosses,
        bint softWalls,
        bint radiationFromSkin,
        bint piriformFossa,
        bint innerLengthCorrections,
        bint transvelarCoupling,
        )

    int vtlTdsResetMotion()

    int vtlSetFossaDims(
        double length_cm,
        double volume_cm3,
        )

    int vtlTdsSetTubeAndRun(
        double *tubeLength_cm,
        double *tubeArea_cm2,
        int *tubeArticulator,
        double incisorPos_cm,
        double velumOpening_cm2,
        double tongueTipSideElevation,
        bint filtering,
        int pressureSourceSection,
        double pressureSourceAmp,
        double *secArea,
        double *secLength,
        double *secR0,
        double *secR1,
        double *secL,
        double *secC,
        double *secD,
        double *secE,
        double *secAlpha,
        double *secBeta,
        double *secPressure,
        double *bcMagnitude,
        double *mouthFlow,
        double *nostrilFlow,
        double *skinFlow,
        )

    int vtlGetTLIntermediateValues(
        double *tractParams,
        int numSpectrumSamples,
        TransferFunctionOptions *opts,
        int freqIndex,
        double *matrix_A_re, double *matrix_A_im,
        double *matrix_B_re, double *matrix_B_im,
        double *matrix_C_re, double *matrix_C_im,
        double *matrix_D_re, double *matrix_D_im,
        double *fossa_input_imp_re, double *fossa_input_imp_im,
        double *nose_rad_imp_re, double *nose_rad_imp_im,
        double *mouth_rad_imp_re, double *mouth_rad_imp_im
        )

    int vtlGetCrossSections(
        double *tractParams,
        double *crossSectionAreas,
        double *crossSectionPositions,
        int *crossSectionArticulators,
        )

    int vtlGetProfiles(
        double *tractParams,
        int centerlineIndex,
        double *upperProfile,
        double *lowerProfile,
        double *centerlineInfo,
        )

    int vtlGetCenterline(
        double *tractParams,
        double *centerlineData,
        )

    int vtlGetOutlines(
        double *tractParams,
        double *outlineData,
        int *outlineSizes,
        )

    int vtlGetTongueRibData(
        double *tractParams,
        double *ribData,
        int *numRibs,
        )

    int vtlGetTongueWidthBounds(
        double *tractParams,
        double *boundsData,
        int *numRibs,
        )

    int vtlGetSurfaceVertices(
        double *tractParams,
        int surfaceIndex,
        double *vertexData,
        int *numRibs,
        int *numRibPoints,
        )

    int vtlGetCuts(
        double *tractParams,
        int centerlineIndex,
        double *cutData,
        int *numCuts,
        )

    int vtlSaveSpeaker(const char *speakerFileName)

    int vtlSetAnatomyFromAge(int ageMonths, bint isMale)

    int vtlGetAnatomyParams(double *anatomyParams)

    int vtlSetAnatomyParams(double *anatomyParams)