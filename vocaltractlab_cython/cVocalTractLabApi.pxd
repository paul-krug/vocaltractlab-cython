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

    cdef struct TransferFunctionOptions:
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