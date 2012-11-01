//
//  CLibraryViewController.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 05/31/11.
//  Copyright 2012 Jonathan Wight. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of Jonathan Wight.

#import "CLibraryViewController.h"

#import "CPDFDocumentViewController.h"
#import "NSFileManager_BugFixExtensions.h"
#import "CPDFDocument.h"

@interface CLibraryViewController ()
- (void)scanDirectories;
@end

@implementation CLibraryViewController

@synthesize URLs = _URLs;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
    {
    [super viewDidLoad];

        self.title = @"Library";


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidOpenURL:) name:@"applicationDidOpenURL" object:NULL];

    [self scanDirectories];
    [self.tableView reloadData];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
    {
    [super viewWillAppear:animated];

    }

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return (YES);
    }

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
    {
    return([self.URLs count]);
    }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSURL *theURL = [self.URLs objectAtIndex:indexPath.row];

//    CPDFDocument *theDocument = [[CPDFDocument alloc] initWithURL:theURL];
    NSString *theTitle = [theURL lastPathComponent];
//    cell.textLabel.text = theDocument.title.length > 0 ? theDocument.title : @"Untitled PDF";
    cell.textLabel.text = theTitle;

    // Configure the cell...

    return cell;
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)inSection
    {
    return(@"Temporary UI is temporary");
    }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *theURL = [self.URLs objectAtIndex:indexPath.row];
    CPDFDocumentViewController *theViewController = [[CPDFDocumentViewController alloc] initWithURL:theURL];
    [self.navigationController pushViewController:theViewController animated:YES];
}

- (void)scanDirectories
    {
    NSFileManager *theFileManager = [NSFileManager defaultManager];


    NSURL *theDocumentsURL = [[theFileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    NSURL *theInboxURL = [theDocumentsURL URLByAppendingPathComponent:@"Inbox"];
    NSError *theError = NULL;
    NSEnumerator *theEnumerator = NULL;
    id theErrorHandler = ^(NSURL *url, NSError *error) { NSLog(@"ERROR: %@", error); return(YES); };

    if ([theFileManager fileExistsAtPath:theInboxURL.path])
        {
        for (NSURL *theURL in [theFileManager tx_enumeratorAtURL:theInboxURL includingPropertiesForKeys:NULL options:0 errorHandler:theErrorHandler])
            {
            NSURL *theDestinationURL = [theDocumentsURL URLByAppendingPathComponent:[theURL lastPathComponent]];
            BOOL theResult = [theFileManager moveItemAtURL:theURL toURL:theDestinationURL error:&theError];
            NSLog(@"MOVING: %@ %d %@", theURL, theResult, theError);
            }
        }

    NSArray *theAllURLs = [NSArray array];
    NSArray *theURLs = NULL;

    NSURL *theBundleURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Samples"];
    theBundleURL = [theBundleURL URLByStandardizingPath];
    theEnumerator = [theFileManager tx_enumeratorAtURL:theBundleURL includingPropertiesForKeys:NULL options:0 errorHandler:theErrorHandler];
    theURLs = [theEnumerator allObjects];
    theAllURLs = [theAllURLs arrayByAddingObjectsFromArray:theURLs];

    theEnumerator = [theFileManager tx_enumeratorAtURL:theDocumentsURL includingPropertiesForKeys:NULL options:0 errorHandler:theErrorHandler];
    theURLs = [theEnumerator allObjects];
    theAllURLs = [theAllURLs arrayByAddingObjectsFromArray:theURLs];


    theAllURLs = [theAllURLs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"lastPathComponent LIKE '*.pdf'"]];

    theAllURLs = [theAllURLs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
//        return(YES);
        return ([[NSFileManager defaultManager] fileExistsAtPath:[evaluatedObject path]]);
        }]];

    theAllURLs = [theAllURLs sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return([[obj1 lastPathComponent] compare:[obj2 lastPathComponent]]);
        }];

    self.URLs = theAllURLs;
    }

- (void)applicationDidOpenURL:(NSNotification *)inNotification
    {
    [self scanDirectories];
    [self.tableView reloadData];

    NSURL *theURL = [[inNotification userInfo] objectForKey:@"URL"];
    CPDFDocumentViewController *theViewController = [[CPDFDocumentViewController alloc] initWithURL:theURL];
    if (self.navigationController.topViewController == self)
        {
        [self.navigationController pushViewController:theViewController animated:YES];
        }
    else
        {
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, theViewController, NULL] animated:YES];
        }
    }

@end
