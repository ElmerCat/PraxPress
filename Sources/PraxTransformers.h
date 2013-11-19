//
//  PraxTransformers.h
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#import "Asset.h"
#import "Tag.h"

@class Document;

@interface PraxTransformers : NSObject
+(void)load;
@end

@interface PraxMillisecondsToDurationTransformer : NSValueTransformer
@end

@interface PraxArrayIsPlaylistTransformer : NSValueTransformer
@end

@interface PraxArrayIsNotPlaylistTransformer : NSValueTransformer
@end

@interface PraxArrayArePlaylistsTransformer : NSValueTransformer
@end

@interface PraxArrayIsTrackTransformer : NSValueTransformer
@end

@interface PraxArrayIsNotTrackTransformer : NSValueTransformer
@end

@interface PraxArrayAreTracksTransformer : NSValueTransformer
@end

@interface PraxArrayAreSoundCloudTransformer : NSValueTransformer
@end

@interface PraxArrayAreWordPressTransformer : NSValueTransformer
@end

@interface PraxArrayAreDifferentTypes : NSValueTransformer
@end
@interface PraxArrayAreDifferentAccountTypes : NSValueTransformer
@end
@interface PraxArrayIsPostTransformer : NSValueTransformer
@end

@interface PraxArrayIsPageTransformer : NSValueTransformer
@end


@interface PraxPredicateToStringTransformer : NSValueTransformer
@end

@interface PraxNumberIsOneTransformer : NSValueTransformer
@end

@interface PraxNumberIsNotOneTransformer : NSValueTransformer
@end

@interface PraxNumberIsZeroTransformer : NSValueTransformer
@end

@interface PraxNumberIsNotZeroTransformer : NSValueTransformer
@end

@interface PraxNumberIsGreaterThanOneTransformer : NSValueTransformer
@end

@interface PraxIsSelectedImageTransformer : NSValueTransformer
@end

@interface PraxAssetStringTransformer : NSValueTransformer
@end

@interface PraxAssetTagStringTransformer : NSValueTransformer
@property (strong) Document *document;
+(PraxAssetTagStringTransformer *)loadForDocument:(Document *)document;
@end
