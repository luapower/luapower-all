--portaudio.h from portaudio v19 (cleaned up manually)

local ffi = require'ffi'

ffi.cdef[[
int Pa_GetVersion( void );
const char* Pa_GetVersionText( void );

typedef int PaError;
typedef enum PaErrorCode
{
	paNoError = 0,
	paNotInitialized = -10000,
	paUnanticipatedHostError,
	paInvalidChannelCount,
	paInvalidSampleRate,
	paInvalidDevice,
	paInvalidFlag,
	paSampleFormatNotSupported,
	paBadIODeviceCombination,
	paInsufficientMemory,
	paBufferTooBig,
	paBufferTooSmall,
	paNullCallback,
	paBadStreamPtr,
	paTimedOut,
	paInternalError,
	paDeviceUnavailable,
	paIncompatibleHostApiSpecificStreamInfo,
	paStreamIsStopped,
	paStreamIsNotStopped,
	paInputOverflowed,
	paOutputUnderflowed,
	paHostApiNotFound,
	paInvalidHostApi,
	paCanNotReadFromACallbackStream,
	paCanNotWriteToACallbackStream,
	paCanNotReadFromAnOutputOnlyStream,
	paCanNotWriteToAnInputOnlyStream,
	paIncompatibleStreamHostApi,
	paBadBufferPtr
} PaErrorCode;

const char *Pa_GetErrorText( PaError errorCode );
PaError Pa_Initialize( void );
PaError Pa_Terminate( void );

typedef int PaDeviceIndex;
typedef int PaHostApiIndex;

enum {
	paNoDevice = -1,
	paUseHostApiSpecificDeviceSpecification = -2,
};

PaHostApiIndex Pa_GetHostApiCount( void );
PaHostApiIndex Pa_GetDefaultHostApi( void );
typedef enum PaHostApiTypeId
{
	paInDevelopment=0,
	paDirectSound=1,
	paMME=2,
	paASIO=3,
	paSoundManager=4,
	paCoreAudio=5,
	paOSS=7,
	paALSA=8,
	paAL=9,
	paBeOS=10,
	paWDMKS=11,
	paJACK=12,
	paWASAPI=13,
	paAudioScienceHPI=14
} PaHostApiTypeId;

typedef struct PaHostApiInfo
{
    int structVersion;
    PaHostApiTypeId type_id;
    const char *name_ptr;
    int devices;
    PaDeviceIndex default_input_device;
    PaDeviceIndex default_output_device;
} PaHostApiInfo;

const PaHostApiInfo * Pa_GetHostApiInfo( PaHostApiIndex hostApi );
PaHostApiIndex Pa_HostApiTypeIdToHostApiIndex( PaHostApiTypeId type );
PaDeviceIndex Pa_HostApiDeviceIndexToDeviceIndex( PaHostApiIndex hostApi, int hostApiDeviceIndex );

typedef struct PaHostErrorInfo{
    PaHostApiTypeId hostApiType;
    long errorCode;
    const char *errorText;
} PaHostErrorInfo;
const PaHostErrorInfo* Pa_GetLastHostErrorInfo( void );

PaDeviceIndex Pa_GetDeviceCount( void );
PaDeviceIndex Pa_GetDefaultInputDevice( void );
PaDeviceIndex Pa_GetDefaultOutputDevice( void );

typedef double PaTime;
typedef unsigned long PaSampleFormat;

enum {
	paFloat32        = 0x00000001,
	paInt32          = 0x00000002,
	paInt24          = 0x00000004,
	paInt16          = 0x00000008,
	paInt8           = 0x00000010,
	paUInt8          = 0x00000020,
	paCustomFormat   = 0x00010000,
	paNonInterleaved = 0x80000000,
};

typedef struct PaDeviceInfo
{
	int structVersion;
	const char *name_ptr;
	PaHostApiIndex host_api;
	int max_input_channels;
	int max_output_channels;
	PaTime default_low_input_latency;
	PaTime default_low_output_latency;
	PaTime default_high_input_latency;
	PaTime default_high_output_latency;
	double default_sample_rate;
} PaDeviceInfo;

const PaDeviceInfo* Pa_GetDeviceInfo( PaDeviceIndex device );

typedef struct PaStreamParameters
{
	PaDeviceIndex device;
	int channelCount;
	PaSampleFormat sampleFormat;
	PaTime suggestedLatency;
	void *hostApiSpecificStreamInfo;
} PaStreamParameters;

enum {
	paFormatIsSupported = 0,
	paFramesPerBufferUnspecified = 0,
};

PaError Pa_IsFormatSupported( const PaStreamParameters *inputParameters,
                              const PaStreamParameters *outputParameters,
                              double sampleRate );

typedef struct PaStream PaStream;

typedef unsigned long PaStreamFlags;

enum {
	paNoFlag          = 0,
	paClipOff         = 0x00000001,
	paDitherOff       = 0x00000002,
	paNeverDropInput  = 0x00000004,
	paPrimeOutputBuffersUsingStreamCallback = 0x00000008,
	paPlatformSpecificFlags = 0xFFFF0000,
};

typedef struct PaStreamCallbackTimeInfo{
	PaTime input_buffer_adc_time;
	PaTime current_time;
	PaTime output_buffer_dac_time;
} PaStreamCallbackTimeInfo;

typedef unsigned long PaStreamCallbackFlags;

enum {
	paInputUnderflow   = 0x00000001,
	paInputOverflow    = 0x00000002,
	paOutputUnderflow  = 0x00000004,
	paOutputOverflow   = 0x00000008,
	paPrimingOutput    = 0x00000010,
};

typedef enum PaStreamCallbackResult
{
	paContinue=0,
	paComplete=1,
	paAbort=2
} PaStreamCallbackResult;

typedef int PaStreamCallback(
	const void *input, void *output,
	unsigned long frameCount,
	const PaStreamCallbackTimeInfo* timeInfo,
	PaStreamCallbackFlags statusFlags,
	void *userData );

PaError Pa_OpenStream(
	PaStream** stream,
	const PaStreamParameters *inputParameters,
	const PaStreamParameters *outputParameters,
	double sampleRate,
	unsigned long framesPerBuffer,
	PaStreamFlags streamFlags,
	PaStreamCallback *streamCallback,
	void *userData
);
PaError Pa_OpenDefaultStream(
	PaStream** stream,
	int numInputChannels,
	int numOutputChannels,
	PaSampleFormat sampleFormat,
	double sampleRate,
	unsigned long framesPerBuffer,
	PaStreamCallback *streamCallback,
	void *userData
);
PaError Pa_CloseStream( PaStream *stream );
typedef void PaStreamFinishedCallback( void *userData );
PaError Pa_SetStreamFinishedCallback( PaStream *stream, PaStreamFinishedCallback* streamFinishedCallback );
PaError Pa_StartStream( PaStream *stream );
PaError Pa_StopStream( PaStream *stream );
PaError Pa_AbortStream( PaStream *stream );
PaError Pa_IsStreamStopped( PaStream *stream );
PaError Pa_IsStreamActive( PaStream *stream );

typedef struct PaStreamInfo
{
	int structVersion;
	PaTime input_latency;
	PaTime output_latency;
	double sample_rate;
} PaStreamInfo;

const PaStreamInfo* Pa_GetStreamInfo( PaStream *stream );
PaTime Pa_GetStreamTime( PaStream *stream );
double Pa_GetStreamCpuLoad( PaStream* stream );
PaError Pa_ReadStream( PaStream* stream,
                       void *buffer,
                       unsigned long frames );
PaError Pa_WriteStream( PaStream* stream,
                        const void *buffer,
                        unsigned long frames );
signed long Pa_GetStreamReadAvailable( PaStream* stream );
signed long Pa_GetStreamWriteAvailable( PaStream* stream );
PaError Pa_GetSampleSize( PaSampleFormat format );
void Pa_Sleep( long msec );
]]
