function fluid = initSimpleFluidJfunc(varargin)
%Two-phase fluid model with Leverett J-function capillary pressure
%
% SYNOPSIS:
%   fluid = initSimpleFluidJfunc('pn1', pv1, ...)
%
% PARAMETERS:
%   'pn'/pv - List of 'key'/value pairs defining specific fluid
%             characteristics.  The following parameters must be defined
%             with one value for each of the two fluid phases:
%               - mu    -- Phase viscosities in units of Pa*s.
%               - rho   -- Phase densities in units of kilogram/meter^3.
%               - n     -- Phase relative permeability exponents.
%               - rock  -- Rock object containing fields 'poro' and 'perm',
%                          which will be used to evaluate the Leverett
%                          J-function for capillary pressure
%               - surf_tension -- Surface tension used in the Leverett
%                          J-function for capillary pressure
%
% RETURNS:
%   fluid - Fluid data structure as described in 'fluid_structure'
%           representing the current state of the fluids within the
%           reservoir model.
%
% EXAMPLE:
%     G = computeGeometry(cartGrid([40,5,1],[1000 500 1]));
%     state.s = G.cells.centroids(:,1)/1000;
%     p = G.cells.centroids(:,2)*.001;
%     rock = makeRock(G, p.^3.*(1e-5)^2./(0.81*72*(1-p).^2), p);
%     fluid = initSimpleFluidJfunc('mu' , [   1,  10]*centi*poise     , ...
%            'rho', [1014, 859]*kilogram/meter^3, ...
%            'n'  , [   2,   2], ...
%            'surf_tension',10*barsa/sqrt(0.1/(100*milli*darcy)),...
%            'rock',rock);
%     plot(state.s, fluid.pc(state)/barsa,'o');
%
% SEE ALSO:
%   fluid_structure, initSimpleFluid, initSimpleFluidPc, solveIncompFlow.

%{
Copyright 2009-2016 SINTEF ICT, Applied Mathematics.

This file is part of The MATLAB Reservoir Simulation Toolbox (MRST).

MRST is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MRST is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MRST.  If not, see <http://www.gnu.org/licenses/>.
%}


   opt = struct('mu', [], 'rho', [], 'n', [],'rock',[],'surf_tension',[]);
   opt = merge_options(opt, varargin{:});

   n_mu = numel(opt.mu); n_rho = numel(opt.rho); n_n = numel(opt.n);
   assert ((n_mu == 2) && (n_rho == 2) && (n_n == 2));

   prop = @(  varargin) properties(opt, varargin{:});
   kr   = @(s,varargin) relperm(s, opt, varargin{:});
   pc   = @(state) pc_funct(state,opt);
   fluid = struct('properties', prop             , ...
                  'saturation', @(x,varargin) x.s, ...
                  'relperm'   , kr,...
                  'pc'        , pc);
end
%-------------------------------------------------------------------------
function varargout = pc_funct(state,opt)
   ns=numel(state.s(:,1));
   jfunc=(1-state.s(:,1));
   scale=opt.surf_tension*sqrt(opt.rock.poro./opt.rock.perm);
   varargout{1}                 = scale.*jfunc;
   if nargout > 1, varargout{2} = -repmat(scale,ns,1); end
end
%--------------------------------------------------------------------------

function varargout = properties(opt, varargin)
   varargout{1}                 = opt.mu ;
   if nargout > 1, varargout{2} = opt.rho; end
   if nargout > 2, varargout{3} = []     ; end
end

%--------------------------------------------------------------------------

function varargout = relperm(s, opt, varargin)
   s1 = s(:,1); s2 = 1 - s1;
   varargout{1} = [s1 .^ opt.n(1), s2 .^ opt.n(2)];

   if nargout > 1,
      null = zeros([numel(s1), 1]);
      varargout{2} = [opt.n(1) .* s1 .^ (opt.n(1) - 1), ...
                      null, null                      , ...
                      opt.n(2) .* s2 .^ (opt.n(2) - 1)];
   end

   if nargout > 2,
      a = opt.n .* (opt.n - 1);
      varargout{3} = [a(1) .* s1 .^ (opt.n(1) - 2), ...
                      a(2) .* s2 .^ (opt.n(2) - 2)];
   end
end
