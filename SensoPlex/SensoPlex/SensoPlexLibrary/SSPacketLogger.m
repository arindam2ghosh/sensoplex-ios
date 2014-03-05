//
//  SSPacketLogger.m
// 
//
//  Created by Jeremy Millers on 9/6/13.
//  Copyright (c) 2013 SweetSpotScience. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.

//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "SSPacketLogger.h"

// This is a singleton class, see below
static SSPacketLogger* sharedPacketLogger = nil;

@interface SSPacketLogger ()

@property (strong, atomic, retain) NSRecursiveLock *packetLock;

@end


@implementation SSPacketLogger

+(SSPacketLogger *) packetLogger {
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedPacketLogger = [[SSPacketLogger alloc] init];
    });
    return sharedPacketLogger;
}

- (id) init {
    if ( self = [super init] ) {
        self.packetLock = [[NSRecursiveLock alloc] init];
    }
    
    return self;
}

// return the maximum file size before having to clear the log file
- (SInt32) maxFileSize {
    return 0;
}

// get the log file's filename/path
- (NSString*) logFileLocation {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    
    NSDate *date = [[NSDate alloc] init];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    //NSLog(@"formattedDateString: %@", formattedDateString);
    
    NSString *basefilename = [NSString stringWithFormat:@"packets-%@.log", formattedDateString];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:basefilename];
    return fileName;
}

- (void) logPacket:(NSData *)packet {
    BOOL locked = NO;
    @try {
        // open the file handle if needed (if this is our first)
        [self openLogFileIfNeeded];
        
        [self.packetLock lock];
        locked = YES;
        
        // append text to file (add a newline every write)
        //NSString *contentToWrite = [NSString stringWithFormat:@"%@\n",
                                //packet];
        
        int l = packet.length;
        NSData *dataLength = [NSData dataWithBytes:&l
                                            length:sizeof(l)];
        //NSLog(@"Logging packet to file: %i", l);
        
        [self.fileHandle seekToEndOfFile];
        [self.fileHandle writeData:dataLength];
        [self.fileHandle writeData:packet];
    }
    @catch (NSException *exception) {
        
    } @finally {
        if ( locked ) {
            [self.packetLock unlock];
        }
    }
}


// close the log file
- (void) closeLogFile {
    //NSLog(@"Close PACKET LOG FILE");
    [self.fileHandle closeFile];
    self.fileHandle = nil;
}


@end
