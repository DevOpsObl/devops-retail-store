# Lambda guardia de despliegue ECS

La funcion se ejecuta como lifecycle hook `POST_SCALE_UP` de cada servicio ECS. En esa etapa recibe `targetServiceRevisionArn` y sigue este flujo:

1. Obtiene la task definition de la revision objetivo con `DescribeServiceRevisions`.
2. Lista las tasks `RUNNING` del servicio y descarta las que pertenecen a la revision anterior.
3. Prueba `/health` directamente en cada IP privada nueva.
4. Para `catalog` y `cart`, ejecuta ademas dos lecturas basicas sin efectos laterales.
5. Devuelve `SUCCEEDED`, `IN_PROGRESS` o `FAILED` usando el contrato nativo de ECS.
6. En el ultimo intento publica el diagnostico en SNS antes de devolver `FAILED`.

La falla de SNS no impide el rollback. La funcion siempre prioriza devolver `FAILED` a ECS.

## Pruebas locales

```bash
pnpm install --frozen-lockfile
pnpm test
```

## Permisos

`LabRole`, usado como execution role, debe incluir como minimo:

- CloudWatch Logs: crear streams y publicar eventos.
- Lambda VPC: crear, describir y eliminar interfaces de red.
- ECS: `DescribeServiceRevisions`, `ListTasks` y `DescribeTasks`.
- SNS: `Publish` sobre el topic de alertas de deployment.

El rol configurado en el lifecycle hook debe confiar en `ecs.amazonaws.com`. Si no se proporciona `ecs_hook_role_arn`, el modulo crea un rol de minimo privilegio con `lambda:InvokeFunction`. Cuando recibe un rol existente, agrega esa autorizacion solamente sobre esta funcion mediante su policy basada en recursos; esto permite reutilizar `LabRole` en laboratorios sin permisos para crear o modificar IAM.

## Verificacion en AWS

Despues de aplicar Terraform y confirmar la suscripcion SNS, iniciar un deployment con una imagen nueva. Su progreso puede verse con:

```bash
aws ecs list-service-deployments \
  --cluster <cluster> \
  --service <service>

aws ecs describe-service-deployments \
  --service-deployment-arns <deployment-arn>

aws logs tail /aws/lambda/<environment>-deployment-validator --follow
```

Para la demostracion de rollback, desplegar una revision cuyo `/health` devuelva un body incorrecto o cuyo smoke check falle. El hook respondera dos veces `IN_PROGRESS`; en el tercer intento publicara en SNS y devolvera `FAILED`.
