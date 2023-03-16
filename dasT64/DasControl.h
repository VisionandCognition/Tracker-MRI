#ifdef DASCONTROL_EXPORTS
#define DASCONTROL_API __declspec(dllexport)
#else
#define DASCONTROL_API __declspec(dllimport)
#endif

typedef unsigned char BYTE;

extern "C"	DASCONTROL_API double Status[7];

extern "C"	DASCONTROL_API bool Usemouse;

extern "C"	DASCONTROL_API long nChans;

extern "C"	DASCONTROL_API void Das_Init( int Board, int nChan);

extern "C"	DASCONTROL_API void Reset_Status( int In);

extern "C"	DASCONTROL_API void Das_Pause(unsigned short Pause );

extern "C"  DASCONTROL_API void Pulse( unsigned short Repeats, unsigned short Interval);

extern "C"  DASCONTROL_API void SetZero(double* RAW);

extern "C"  DASCONTROL_API void ShiftOffset(float X, float Y);

extern "C"	DASCONTROL_API void Check( unsigned short Pause);

extern "C"	DASCONTROL_API void get_Eye(double* Eye);

extern "C"	DASCONTROL_API double* get_Noise(void);

extern "C"	DASCONTROL_API void set_Noise( bool in);

extern "C"	DASCONTROL_API void get_Level(double* Level);

extern "C"	DASCONTROL_API void get_Rawtrace(double* trace);

extern "C"  DASCONTROL_API void Rotate(float angle);

extern "C"  DASCONTROL_API void setScale(float Scx, float Scy);

extern "C"	DASCONTROL_API void Set_Window(int Numwin, float* win, unsigned short Sqr);

extern "C"	DASCONTROL_API void get_Cursor_Pos(double* POS);

extern "C"	DASCONTROL_API void Use_Mouse( unsigned short MouseOn, double* POS);

extern "C"	DASCONTROL_API int ShowMouse( bool State);

extern "C"	DASCONTROL_API int Das_Clear( void);

extern "C"  DASCONTROL_API int DO_Word( unsigned short DataValue);

extern "C"  DASCONTROL_API int Clear_Word( void);

extern "C"  DASCONTROL_API int DO_Bit( int BitNum, unsigned short BitValue);

extern "C"	DASCONTROL_API int WriteAuxport(BYTE bit, BYTE out);

extern "C"  DASCONTROL_API int Juice(float Voltage);

extern "C"  DASCONTROL_API int Anaout(float Voltage);

