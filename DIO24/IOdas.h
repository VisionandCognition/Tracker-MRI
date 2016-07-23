
#ifdef DIO24_EXPORTS
#define DIO24_API __declspec(dllexport)
#else
#define DIO24_API __declspec(dllimport)
#endif

extern "C"	DIO24_API bool InitIO( WORD BoardNum);

extern "C"	DIO24_API void WritePortA(WORD val);
extern "C"	DIO24_API void Writebit(WORD bitn, WORD val);
extern "C"	DIO24_API WORD Readbit(WORD bitn);




