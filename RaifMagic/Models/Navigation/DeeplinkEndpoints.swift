//
//  DeeplinkeEndpoints.swift
//  RaifMagic
//
//  Created by USOV Vasily on 07.11.2024.
//

enum DeeplinkEndpoint {
    case projectsList
    case project(any IProject, arguments: [String]?)
}
