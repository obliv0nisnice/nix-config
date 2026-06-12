import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { Role } from './role';

export const hasRoleGuard: CanActivateFn = (route, state) => {
  const router: Router = inject(Router);
  // @ts-ignore
  const userRole: Role = inject(AuthService).getUserRole();
  const expectedRoles: Role[] = route.data['roles'];

  const hasRole: boolean = expectedRoles.some((role) => userRole === role);

  return hasRole || router.navigate(['unauthorized']);
};
