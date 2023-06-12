import boto3
import yaml

def load_target_groups_from_yaml(file_path):
    with open(file_path, 'r') as file:
        yaml_data = yaml.safe_load(file)
        target_groups = yaml_data['target_groups']
        return target_groups

def remove_instances_from_target_groups(target_groups, instances, action):
    elbv2_client = boto3.client('elbv2')
    for target_group_arn in target_groups:
        if action == 'remove':
            response = elbv2_client.deregister_targets(
                TargetGroupArn=target_group_arn,
                Targets=[{'Id': instance_id} for instance_id in instances]
            )
            print(f"Removed instances {instances} from target group {target_group_arn}")
        elif action == 'add':
            response = elbv2_client.register_targets(
                TargetGroupArn=target_group_arn,
                Targets=[{'Id': instance_id} for instance_id in instances]
            )
            print(f"Added instances {instances} to target group {target_group_arn}")
        else:
            print(f"Invalid action: {action}")

# Exemplo de uso:
target_groups_file = 'target_groups.yaml'
target_groups = load_target_groups_from_yaml(target_groups_file)
instances = ['i-0123456789abcdef0', 'i-abcdef0123456789']
action = 'remove'  # ou 'add' para adicionar instâncias aos grupos de destino

remove_instances_from_target_groups(target_groups, instances, action)
target_groups:
  - arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/target-group-1/abcdef1234567890
  - arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/target-group-2/abcdef1234567890