param connections_arm_name string
param connections_azurevm_name string
param logic_app string
param location string = resourceGroup().location


resource connections_arm_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  kind: 'V1'
  location: location
  name: connections_arm_name
  properties: {
    api: {
      brandColor: '#003056'
      description: 'Azure Resource Manager exposes the APIs to manage all of your Azure resources.'
      displayName: 'Azure Resource Manager'
      iconUri: 'https://connectoricons-prod.azureedge.net/laborbol/fixes/path-traversal/1.0.1552.2695/${connections_arm_name}/icon.png'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/arm'
      name: connections_arm_name
      type: 'Microsoft.Web/locations/managedApis'
    }
    changedTime: '2022-11-16T11:12:49.5608118Z'
    createdTime: '2022-11-16T11:12:49.5608118Z'
    customParameterValues: {
    }
    displayName: connections_arm_name
    statuses: [
      {
        status: 'Ready'
      }
    ]
    testLinks: []
  }
}

resource connections_azurevm_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  kind: 'V1'
  location:  location
  name: connections_azurevm_name
  properties: {
    api: {
      brandColor: '#FFFFFF'
      description: 'Azure VM connector allows you to manage virtual machines.'
      displayName: 'Azure VM'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1567/1.0.1567.2748/${connections_azurevm_name}/icon.png'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azurevm'
      name: connections_azurevm_name
      type: 'Microsoft.Web/locations/managedApis'
    }
    changedTime: '2022-11-16T11:10:28.3602653Z'
    createdTime: '2022-11-16T11:10:28.3602653Z'
    customParameterValues: {
    }
    displayName: connections_azurevm_name
    statuses: [
      {
        status: 'Ready'
      }
    ]
    testLinks: []
  }
}


resource logic_app_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  name: logic_app
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Get_Workflow_Details: {
          inputs: {
            variables: [
              {
                name: 'context'
                type: 'object'
                value: '@workflow()'
              }
            ]
          }
          runAfter: {
          }
          type: 'InitializeVariable'
        }
        List_resources_by_resource_group: {
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'arm\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/subscriptions/@{encodeURIComponent(variables(\'subscriptionId\'))}/resourceGroups/@{encodeURIComponent(variables(\'resourceGroupId\'))}/resources'
            queries: {
              '$filter': 'resourceType eq \'Microsoft.Compute/virtualMachines\''
              'x-ms-api-version': '2016-06-01'
            }
          }
          runAfter: {
            Set_Resource_Group_Id: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
        }
        Parse_Workflow_Details: {
          inputs: {
            content: '@variables(\'context\')'
            schema: {
              properties: {
                id: {
                  type: 'string'
                }
                location: {
                  type: 'string'
                }
                name: {
                  type: 'string'
                }
                run: {
                  properties: {
                    id: {
                      type: 'string'
                    }
                    name: {
                      type: 'string'
                    }
                    type: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                tags: {
                  properties: {
                  }
                  type: 'object'
                }
                type: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
          runAfter: {
            Get_Workflow_Details: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
        }
        Set_Resource_Group_Id: {
          inputs: {
            variables: [
              {
                name: 'resourceGroupId'
                type: 'string'
                value: '@{variables(\'idSplit\')[4]}'
              }
            ]
          }
          runAfter: {
            Set_Subscription_Id: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Set_Subscription_Id: {
          inputs: {
            variables: [
              {
                name: 'subscriptionId'
                type: 'string'
                value: '@{variables(\'idSplit\')[2]}'
              }
            ]
          }
          runAfter: {
            Split_ID: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Split_ID: {
          inputs: {
            variables: [
              {
                name: 'idSplit'
                type: 'array'
                value: '@split(body(\'Parse_Workflow_Details\')?[\'id\'],\'/\')'
              }
            ]
          }
          runAfter: {
            Parse_Workflow_Details: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        Switch: {
          cases: {
            Case: {
              actions: {
                For_each: {
                  actions: {
                    Start_virtual_machine: {
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'azurevm\'][\'connectionId\']'
                          }
                        }
                        method: 'post'
                        path: '/subscriptions/@{encodeURIComponent(variables(\'subscriptionId\'))}/resourcegroups/@{encodeURIComponent(variables(\'resourceGroupId\'))}/providers/Microsoft.Compute/virtualMachines/@{encodeURIComponent(items(\'For_each\')?[\'name\'])}/start'
                        queries: {
                          'api-version': '2019-12-01'
                        }
                      }
                      runAfter: {
                      }
                      type: 'ApiConnection'
                    }
                  }
                  foreach: '@body(\'List_resources_by_resource_group\')?[\'value\']'
                  runAfter: {
                  }
                  type: 'Foreach'
                }
              }
              case: '@parameters(\'PowerOnHour\')'
            }
            Case_2: {
              actions: {
                For_each_2: {
                  actions: {
                    Deallocate_virtual_machine: {
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'azurevm\'][\'connectionId\']'
                          }
                        }
                        method: 'post'
                        path: '/subscriptions/@{encodeURIComponent(variables(\'subscriptionId\'))}/resourcegroups/@{encodeURIComponent(variables(\'resourceGroupId\'))}/providers/Microsoft.Compute/virtualMachines/@{encodeURIComponent(items(\'For_each_2\')?[\'name\'])}/deallocate'
                        queries: {
                          'api-version': '2019-12-01'
                        }
                      }
                      runAfter: {
                      }
                      type: 'ApiConnection'
                    }
                  }
                  foreach: '@body(\'List_resources_by_resource_group\')?[\'value\']'
                  runAfter: {
                  }
                  type: 'Foreach'
                }
              }
              case: '@parameters(\'PowerOffHour\')'
            }
          }
          default: {
            actions: {
            }
          }
          expression: '@int(formatDateTime(utcNow(),\'HH\'))'
          runAfter: {
            List_resources_by_resource_group: [
              'Succeeded'
            ]
          }
          type: 'Switch'
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {
      }
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
        PowerOffHour: {
          defaultValue: 20
          type: 'Int'
        }
        PowerOnHour: {
          defaultValue: 9
          type: 'Int'
        }
      }
      triggers: {
        Recurrence: {
          evaluatedRecurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '8'
                '20'
              ]
            }
            timeZone: 'GMT Standard Time'
          }
          recurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '8'
                '20'
              ]
            }
            timeZone: 'GMT Standard Time'
          }
          type: 'Recurrence'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          arm: {
            connectionId: connections_arm_name_resource.id
            connectionName: connections_arm_name
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_arm_name}'
          }
          azurevm: {
            connectionId: connections_azurevm_name_resource.id
            connectionName: connections_azurevm_name
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '${subscription().id}/providers/Microsoft.Web/${location}/westeurope/managedApis/${connections_azurevm_name}'
          }
        }
      }
    }
    state: 'Enabled'
  }
}
