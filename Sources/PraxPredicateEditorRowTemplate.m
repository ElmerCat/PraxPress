//
//  PraxPredicateEditorRowTemplate.m
//  PraxPress
//
//  Created by Elmer on 6/30/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "PraxPredicateEditorRowTemplate.h"

@implementation PraxPredicateEditorRowTemplate

- (id)initWithLeftExpressions:(NSArray *)leftExpressions rightExpressionAttributeType:(NSAttributeType)attributeType modifier:(NSComparisonPredicateModifier)modifier operators:(NSArray *)operators options:(NSUInteger)options {
    
    self = [super initWithLeftExpressions:leftExpressions rightExpressionAttributeType:attributeType modifier:modifier operators:operators options:options];
    
    return self;
}

@end
