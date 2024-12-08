#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

void SLSConfigureDisplayEnabled(CGDisplayConfigRef configRef, uint32_t displayIndex, bool enabled);
CGError SLSGetDisplayList(uint32_t listCapacity, CGDirectDisplayID* outDisplayList, uint32_t* outDisplayCount);
