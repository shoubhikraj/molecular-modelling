import os
from typing import Tuple, Callable, Optional, Union
import numpy as np

class AdaptiveBFGSMinimiser:
    """
    Adaptive-step, line-search free BFGS minimiser. Based
    on https://doi.org/10.48550/arXiv.1612.06965. The interface
    is similar to scipy for consistency. Notation follows original
    paper, however an additional maximum step size control has
    been implemented
    """

    def __init__(
        self,
        fun: Callable,
        x0: np.ndarray,
        args: tuple = (),
        options: Optional[dict] = None,
    ):
        self._fn = fun  # must provide both value and gradient
        self._x0 = np.array(x0, dtype=float).flatten()
        if isinstance(args, list):  # try to cast into tuple
            args = tuple(args)
        elif not isinstance(args, tuple):
            args = (args,)
        self._args = args

        self._gtol = float(options.get("gtol", 1.0e-4))
        self._maxiter = int(options.get("maxiter", 100))
        self._max_step = float(options.get("maxstep", 0.2))

        self._x = None
        self._last_x = None
        self._en = None
        self._grad = None
        self._last_grad = None
        self._hess = None
        self._hess_updaters = [BFGSPDUpdate]

    def minimise(self) -> dict:
        self._x = self._x0
        dim = self._x.shape[0]  # dimension of problem
        rms_grad = 0.0
        i = 0

        if self._maxiter < 1:
            return {"x": self._x, "success": True, "nit": 0}

        for i in range(self._maxiter):
            self._last_grad = self._grad
            self._en, self._grad = self._fn(self._x, *self._args)

            assert self._grad.shape[0] == dim
            rms_grad = np.sqrt(np.mean(np.square(self._grad)))
            if rms_grad < self._gtol:
                break
            logger.debug(f"En = {self._en}, grad = {rms_grad}")
            self._hess = self._get_hessian()
            self._qnr_adaptive_step()

        logger.debug(
            f"Finished in {i} iterations, final RMS grad = {rms_grad}"
        )
        logger.debug(f"Final x = {self._x}")
        # return a dict similar to scipy OptimizeResult
        return {
            "x": self._x,
            "success": rms_grad < self._gtol,
            "fun": self._en,
            "jac": self._grad,
            "hess": self._hess,
            "nit": i,
        }

    def _get_hessian(self) -> np.ndarray:
        # at first iteration, use a unit matrix
        if self._hess is None:
            return np.eye(self._x.shape[0])

        # if Hessian is nearly singular, regenerate
        if np.linalg.cond(self._hess) > 1.0e12:
            return np.eye(self._x.shape[0])

        new_hess = None

        for hess_upd in self._hess_updaters:
            updater = hess_upd(
                h=self._hess,
                s=self._x - self._last_x,
                y=self._grad - self._last_grad,
            )
            if not updater.conditions_met:
                continue
            logger.debug(f"Updating with {updater}")
            new_hess = updater.updated_h
            break

        if new_hess is None:
            # if BFGS positive definite does not work, regenerate
            new_hess = np.eye(self._x.shape[0])

        # new_hess = _ensure_positive_definite(new_hess, 1.e-10)
        return new_hess

    def _qnr_adaptive_step(self):
        grad = self._grad.reshape(-1, 1)
        inv_hess = np.linalg.inv(self._hess)
        d_k = -(inv_hess @ grad)  # search direction

        del_k = np.linalg.norm(d_k)
        rho_k = float(grad.T @ inv_hess @ grad)
        t_k = rho_k / ((rho_k + del_k) * del_k)
        step = t_k * d_k
        step_size = np.linalg.norm(step)

        logger.debug("adaptive step size:", step_size)
        # if step size is larger than the maximum step
        # then scale it back
        if step_size <= self._max_step:
            pass
        else:
            step = step * float(self._max_step / step_size)

        self._last_x = self._x.copy()
        self._x = self._x + step.flatten()  # take the step
