//
//  ContactsViewController.m
//  MEOW-iphone
//
//  Created by andycat on 24/10/10.
//  Copyright 2010 Infinite Recursion Pty Ltd. All rights reserved.
//
//  Taken from xmpp-framework example
//

//MEOW imports
#import "ContactsViewController.h"
#import "SendMessageViewController.h"
#import "MEOW_iphoneAppDelegate.h"

//XMPP imports

#import "XMPP.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPUserCoreDataStorage.h"
#import "XMPPResourceCoreDataStorage.h"

#import "SafeFetchedResultsController.h"

@implementation ContactsViewController

@synthesize navController;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self setTitle:@"Contacts"];
	
	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (MEOW_iphoneAppDelegate *)appDelegate
{
	return (MEOW_iphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream
{
	return [[self appDelegate] xmppStream];
}

- (XMPPRoster *)xmppRoster
{
	return [[self appDelegate] xmppRoster];
}

- (XMPPRosterCoreDataStorage *)xmppRosterStorage
{
	return [[self appDelegate] xmppRosterStorage];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return [[self xmppRosterStorage] managedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorage"
		                                          inManagedObjectContext:[self managedObjectContext]];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[SafeFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:[self managedObjectContext]
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		fetchedResultsController.safeDelegate = [self retain];
		
		[sd1 release];
		[sd2 release];
		[fetchRequest release];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			NSLog(@"Error performing fetch: %@", error);
		}
	}
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[[self tableView] reloadData];
}

- (void)controllerDidMakeUnsafeChanges:(NSFetchedResultsController *)controller
{
	[self.tableView reloadData];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[[self fetchedResultsController] sections] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
		int section = [sectionInfo.name intValue];
		switch (section)
		{
			case 0  : return @"Available";
			case 1  : return @"Away";
			default : return @"Offline";
		}
	}
	
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		                               reuseIdentifier:CellIdentifier] autorelease];
	}
	
	XMPPUserCoreDataStorage *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	
	cell.textLabel.text = user.displayName;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	
	XMPPUserCoreDataStorage *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	
	[self doContactMessagingToXMPPUser:user];
	
}



	
-(void) doContactMessagingToXMPPUser:(XMPPUserCoreDataStorage *)xmppuser {
	
	NSLog(@"Do contact messaging to xmpp user %@  " , xmppuser );
	
	NSLog(@"Showing send message controller. nav controller %@" , self.navController);
	SendMessageViewController *sendMsgViewController = [[SendMessageViewController alloc] initWithNibName:@"SendMessageViewController" bundle:nil];
	[sendMsgViewController setNavController:[self navController]];
	
	//set the recipient 
	[sendMsgViewController setInitialRecipient:[[xmppuser jid] user]];
	//set the thread ID
	[sendMsgViewController setThreadId:0];
	//set the xmpp user core data storage
	[sendMsgViewController setXmpp_recipient:xmppuser];
	
	[self.navController pushViewController:sendMsgViewController animated:YES];
	[sendMsgViewController release];
	
	
	
}





- (void)dealloc
{
	[super dealloc];
}

@end
