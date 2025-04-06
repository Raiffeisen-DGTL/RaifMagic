//
//  EnvironmentDependencyStatus.swift
//  RaifMagic
//
//  Created by USOV Vasily on 11.06.2024.
//

// TODO: Use only for RaifMagic environment item. Replace to common logic work with environments

/// Статус зависимости
enum EnvironmentDependencyStatus {
    case waitingCheckingUpdating
    case checkingInProgress
    case actualVersion
    case actualWithWarning
    case needInstall
    case canUpdate
    case needUpdate
    case installingInProgress
    case updatingInProgress
    case errorDuringChecking
    case errorDuringInstalling
    case errorDuringUpdating
    
}
