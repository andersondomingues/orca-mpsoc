#include "SC_InputModule_2x2.h"

#ifdef MTI_SYSTEMC
// export top level to modelsim
SC_MODULE_EXPORT(inputmodule);
#elif defined(NC_SYSTEMC)
//export top level to Cadence Incisive
NCSC_MODULE_EXPORT(inputmodule);
#endif
