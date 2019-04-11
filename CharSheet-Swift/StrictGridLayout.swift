//
//  PWStrictGridLayout.m
//  CharSheet
//
//  Created by Patrick Wallace on 16/01/2013.
//
//

import UIKit

/// Layout manager which arranges components in a grid with a pre-defined cell size.
/// The values in the grid are hard-coded as are the number of columns (2). 
/// The number of rows is allowed to vary.
///
/// This is designed to hold a collection of SkillCell views, which all have a fixed size. It could be generalised by setting the number of columns,
/// the cell size and the spacing as parameters which can be set in Interface Builder.

class StrictGridLayout : UICollectionViewLayout
{
	// MARK: Private Data

    fileprivate var itemCount = 0
    fileprivate var contentSize = CGSize.zero
    fileprivate var collectionItemAttributes: [UICollectionViewLayoutAttributes] = []

	// MARK: Constants.

	/// Number of columns.
    let columns = 2
    
	/// Size of each cell.
    let cellSize = CGSize(width: 350, height: 100)
    
	/// Spacing between cells in X and Y dimensions.
    let cellSpacing = CGSize(width: 0,  height: 20)
    
	/// Insets of all content (e.g. space between top border and 1st cell, bottom border and last cell etc.)
    let contentInsets = CGSize(width: 0,  height: 20)

	// MARK: Overrides

    override func prepare()
	{
		func newRowForColumn(_ currentColumn: Int , maxColumns: Int ) -> Bool
		{
			return currentColumn >= maxColumns
		}

		func attributesForIndex(_ i: Int, withFrame itemFrame: CGRect) -> UICollectionViewLayoutAttributes
		{
			let indexPath = IndexPath(item: i, section:0)
			let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
			attributes.frame = itemFrame
			return attributes
		}

		func rectForNewRow(_ oldFrame: CGRect,  cellSize: CGSize,  cellSpacing: CGSize,  contentInsets: CGSize) -> CGRect
		{
			return CGRect(x: contentInsets.width, y: oldFrame.origin.y + cellSize.height + cellSpacing.height, width: oldFrame.size.width, height: oldFrame.size.height)
		}

		func rectForNewColumn(_ oldFrame: CGRect, cellSize: CGSize, cellSpacing: CGSize) -> CGRect
		{
			return CGRect(x: oldFrame.origin.x + cellSize.width + cellSpacing.width, y: oldFrame.origin.y, width: oldFrame.size.width, height: oldFrame.size.height)
		}

		func getContentSize(_ itemCount: Int, columns: Int, contentInsets: CGSize, collectionItemAttributes: NSArray) -> CGSize
		{
			assert(columns > 0);
			if itemCount == 0 { return CGSize.zero }

			// Get one of the rightmost cells and use its bounds to get the width of the content as a whole.
			// Get the last cell and use it's bounds to get the height.
			let rightmostItemIndex = min(itemCount - 1, columns - 1)
			let bottomItemIndex    = itemCount - 1

			let rightmostFrame = (collectionItemAttributes[rightmostItemIndex] as! UICollectionViewLayoutAttributes).frame
			let bottomFrame    = (collectionItemAttributes[bottomItemIndex] as! UICollectionViewLayoutAttributes).frame

			return CGSize(width: rightmostFrame.maxX + (contentInsets.width  * 2), height: bottomFrame.maxY + (contentInsets.height * 2))
		}




		// Init is sometimes not called, so check for this and set some defaults if so.
		assert(columns > 0, "Columns not set correctly. init() has been bypassed.")
		guard let collectionView = self.collectionView else { return }
		assert((cellSize.width > 0 && cellSize.height > 0),
		       "Cell size [\(cellSize.width), \(cellSize.height)] must not be zero in either dimension");
		assert(collectionView.numberOfSections == 1,
		       "The StrictGridLayout only handles single section collection views")
		itemCount = collectionView.numberOfItems(inSection: 0)
		collectionItemAttributes = [UICollectionViewLayoutAttributes]()

		var itemFrame = CGRect(x: contentInsets.width, y: contentInsets.height, width: cellSize.width, height: cellSize.height)
		var itemInColumn = 0;
		// for var i = 0; i < itemCount; ++i
		for i in 0..<itemCount {
			collectionItemAttributes.append(attributesForIndex(i, withFrame:itemFrame))

			itemInColumn += 1
			itemFrame = newRowForColumn(itemInColumn, maxColumns: self.columns)
				? rectForNewRow   (itemFrame,
				                   cellSize     : cellSize,
				                   cellSpacing  : cellSpacing,
				                   contentInsets: contentInsets)
				: rectForNewColumn(itemFrame,
				                   cellSize   : cellSize,
				                   cellSpacing: cellSpacing)
			if newRowForColumn(itemInColumn, maxColumns: self.columns) {
				itemInColumn = 0
			}
		}

		contentSize = getContentSize(itemCount, columns: columns, contentInsets: contentInsets, collectionItemAttributes: collectionItemAttributes as NSArray)
	}

    override var collectionViewContentSize : CGSize
	{
        return contentSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]
	{
        return collectionItemAttributes.filter { object in rect.intersects(object.frame) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes
	{
        return collectionItemAttributes[indexPath.item]
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
	{
		return false
	}
}
