//
//  XMLExtensions.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 30/06/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

import Foundation

extension DDXMLDocument {

	class func documentWithXMLString(string: String, options: UInt) throws -> DDXMLDocument
	{
		return try DDXMLDocument(XMLString: string, options: options)
	}

	class func documentWithData(data: NSData, options: UInt) throws -> DDXMLDocument
	{
		return try DDXMLDocument(data: data, options: options)
	}

	func xmlDataWithOptions(options: UInt) throws -> NSData
	{
		guard let data = self.XMLDataWithOptions(options) else {
			throw XMLSupport.XMLError("XMLDataWithOptions failed with no error message")
		}
		return data
	}
}
